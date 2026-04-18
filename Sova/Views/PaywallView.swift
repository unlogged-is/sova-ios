import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    var store: StoreManager = .shared

    @State private var selectedProduct: Product?
    @State private var isPurchasing: Bool = false
    @State private var loadFailed: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    features
                    plans
                    purchaseButton
                    footer
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(.sovaBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
                if store.products.isEmpty {
                    loadFailed = true
                }
            }
            if selectedProduct == nil {
                selectedProduct = store.yearlyProduct
            }
        }
        .onChange(of: store.products) { _, _ in
            if selectedProduct == nil {
                selectedProduct = store.yearlyProduct
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.sovaWarmAccent)

            Text("Sova Pro")
                .font(SovaFont.appTitle(size: 40))
                .foregroundStyle(.sovaPrimaryAccent)

            Text("Unlock the full experience")
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    // MARK: - Features

    private var features: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureRow(icon: "infinity", text: "Unlimited items")
            featureRow(icon: "doc.viewfinder", text: "Document & receipt scanning")
            featureRow(icon: "checkmark.shield.fill", text: "Warranties & receipt tracking")
            featureRow(icon: "folder.badge.plus", text: "Custom categories")
            featureRow(icon: "person.2.fill", text: "Family Sharing included")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.sovaSurface, in: .rect(cornerRadius: 20))
        .sovaCard(cornerRadius: 20)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.sovaPrimaryAccent)
                .frame(width: 28)
            Text(text)
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaPrimaryText)
        }
    }

    // MARK: - Plans

    private var plans: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty && !loadFailed {
                ProgressView("Loading plans...")
                    .font(SovaFont.body(.subheadline))
                    .foregroundStyle(.sovaSecondaryText)
                    .padding(.vertical, 20)
            }
            if store.products.isEmpty && loadFailed {
                VStack(spacing: 8) {
                    Text("Unable to load plans")
                        .font(SovaFont.body(.subheadline, weight: .semibold))
                        .foregroundStyle(.sovaPrimaryText)
                    Text("Check your connection and try again.")
                        .font(SovaFont.mono(.caption))
                        .foregroundStyle(.sovaSecondaryText)
                    Button("Retry") {
                        loadFailed = false
                        Task {
                            await store.loadProducts()
                            if store.products.isEmpty { loadFailed = true }
                        }
                    }
                    .font(SovaFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(.sovaPrimaryAccent)
                    .padding(.top, 4)
                }
                .padding(.vertical, 20)
            }
            if let monthly = store.monthlyProduct {
                planCard(
                    product: monthly,
                    title: "Monthly",
                    price: monthly.displayPrice
                )
            }
            if let yearly = store.yearlyProduct {
                planCard(
                    product: yearly,
                    title: "Yearly",
                    price: yearly.displayPrice,
                    detail: yearlySavingsDetail(yearly)
                )
            }
            if let lifetime = store.lifetimeProduct {
                planCard(
                    product: lifetime,
                    title: "Lifetime",
                    price: lifetime.displayPrice,
                    detail: "one-time purchase"
                )
            }
        }
    }

    private func planCard(product: Product, title: String, price: String, detail: String? = nil) -> some View {
        let isSelected = selectedProduct?.id == product.id
        return Button {
            withAnimation(SovaAccessibility.animation(.snappy(duration: 0.2))) {
                selectedProduct = product
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(SovaFont.body(.headline, weight: .semibold))
                        .foregroundStyle(.sovaPrimaryText)
                    if let detail {
                        Text(detail)
                            .font(SovaFont.mono(.caption))
                            .foregroundStyle(.sovaSecondaryText)
                    }
                }
                Spacer()
                Text(price)
                    .font(SovaFont.body(.title3, weight: .semibold))
                    .foregroundStyle(.sovaPrimaryText)
            }
            .padding(16)
            .background(
                isSelected ? Color.sovaPrimaryAccent.opacity(0.1) : .sovaSurface,
                in: .rect(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .sovaPrimaryAccent : .sovaCardBorder, lineWidth: isSelected ? 2 : 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func yearlySavingsDetail(_ yearly: Product) -> String? {
        guard let monthly = store.monthlyProduct else { return nil }
        let monthlyAnnual = NSDecimalNumber(decimal: monthly.price * 12)
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price)
        let saved = monthlyAnnual.subtracting(yearlyPrice)
        if saved.doubleValue > 0 {
            let percent = Int((saved.doubleValue / monthlyAnnual.doubleValue * 100).rounded())
            return "Save \(percent)%"
        }
        return nil
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                guard let product = selectedProduct else { return }
                isPurchasing = true
                Task {
                    _ = await store.purchase(product)
                    isPurchasing = false
                }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(.sovaBackground)
                    } else {
                        Text(selectedProduct?.id == StoreManager.lifetimeID ? "Purchase" : "Subscribe")
                            .font(SovaFont.body(.headline, weight: .semibold))
                    }
                }
                .foregroundStyle(.sovaBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.sovaPrimaryAccent, in: .rect(cornerRadius: 16))
            }
            .disabled(selectedProduct == nil || isPurchasing)
            .opacity(selectedProduct == nil ? 0.5 : 1)

            if let error = store.purchaseError {
                Text(error)
                    .font(SovaFont.mono(.caption))
                    .foregroundStyle(.sovaOverdue)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            Button("Restore purchases") {
                Task { await store.restore() }
            }
            .font(SovaFont.body(.subheadline))
            .foregroundStyle(.sovaSecondaryText)

            Text("Subscriptions renew automatically. Cancel anytime in Settings. Lifetime is a one-time purchase.")
                .font(SovaFont.mono(.caption2))
                .foregroundStyle(.sovaSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }
}
