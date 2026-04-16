import StoreKit
import SwiftUI

@MainActor
@Observable
final class StoreManager {

    static let shared = StoreManager()

    // MARK: - Product IDs

    static let monthlyID = "sova_pro_monthly"
    static let yearlyID = "sova_pro_yearly"
    static let lifetimeID = "sova_pro_lifetime"
    static let allProductIDs: Set<String> = [monthlyID, yearlyID, lifetimeID]

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var isPro: Bool = false
    private(set) var purchaseError: String?

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }

    // MARK: - Free tier limit

    static let freeItemLimit = 3

    // MARK: - Private

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshEntitlements() }
    }

    nonisolated deinit {
        // transactionListener will be cancelled when the Task is deallocated
    }

    // MARK: - Load products

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.allProductIDs)
                .sorted { $0.price < $1.price }
        } catch {
            purchaseError = "Failed to load products."
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = "Purchase failed. Please try again."
            return false
        }
    }

    // MARK: - Restore

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        // Check for lifetime (non-consumable)
        if let result = await Transaction.latest(for: Self.lifetimeID) {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                isPro = true
                return
            }
        }

        // Check for active subscription
        for id in [Self.yearlyID, Self.monthlyID] {
            if let result = await Transaction.latest(for: id) {
                if case .verified(let transaction) = result,
                   transaction.revocationDate == nil,
                   transaction.expirationDate ?? .distantFuture > Date.now {
                    isPro = true
                    return
                }
            }
        }

        isPro = false
    }

    // MARK: - Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.unverified
        case .verified(let value):
            return value
        }
    }

    enum StoreError: Error {
        case unverified
    }
}
