import SwiftUI

struct LegalSettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    LegalPageView(title: "Privacy Policy", sections: LegalText.privacyPolicy)
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaPrimaryText)
                }
                NavigationLink {
                    LegalPageView(title: "Terms of Use", sections: LegalText.termsOfUse)
                } label: {
                    Label("Terms of Use", systemImage: "doc.plaintext")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaPrimaryText)
                }
                NavigationLink {
                    LegalPageView(title: "Disclaimer", sections: LegalText.disclaimer)
                } label: {
                    Label("Disclaimer", systemImage: "exclamationmark.shield")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaPrimaryText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.sovaBackground)
        .navigationTitle("Legal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LegalPageView: View {
    let title: String
    let sections: [LegalSection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 8) {
                        if let heading = section.heading {
                            Text(heading)
                                .font(SovaFont.body(.headline, weight: .semibold))
                                .foregroundStyle(.sovaPrimaryText)
                        }
                        Text(section.body)
                            .font(SovaFont.body(.subheadline))
                            .foregroundStyle(.sovaSecondaryText)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(.sovaBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LegalSection {
    let heading: String?
    let body: String
}

// swiftlint:disable line_length
enum LegalText {
    static let privacyPolicy: [LegalSection] = [
        LegalSection(heading: nil, body: "This Privacy Policy describes how Sova (the \"App\") handles your information. Sova is developed and maintained by unlogged LLC (\"we,\" \"our,\" or \"us\")."),
        LegalSection(heading: "Data We Collect", body: "None. Sova does not collect, store, transmit, or share any personal data. We do not use analytics frameworks, advertising SDKs, crash reporting services, or any third-party tools that collect user information."),
        LegalSection(heading: "Data Storage", body: "All data you enter into Sova -- including items, maintenance schedules, photos, warranty details, and receipts -- is stored locally on your device using Apple's SwiftData framework.\n\nIf you enable iCloud on your device, Sova will sync your data across your Apple devices using Apple's CloudKit service. This sync is handled entirely by Apple's infrastructure and governed by Apple's privacy policy. We do not operate any servers and have no access to your iCloud data."),
        LegalSection(heading: "No Accounts", body: "Sova does not require or offer user accounts. There is no sign-up, no login, and no email collection. You can use the full app without providing any personal information."),
        LegalSection(heading: "Photos", body: "Photos taken or imported within Sova are stored locally on your device and, if iCloud is enabled, within your private iCloud container. Photos are never uploaded to our servers or shared with third parties because we do not operate any servers."),
        LegalSection(heading: "Subscriptions", body: "Sova Pro subscriptions are processed entirely through Apple's App Store. We do not receive or store your payment information. Apple manages all billing, and their privacy practices govern that transaction. We receive only anonymized subscription status information from Apple (active, expired, etc.) to determine whether to unlock Pro features."),
        LegalSection(heading: "Notifications", body: "If you grant notification permission, Sova schedules local notifications on your device to remind you of upcoming maintenance tasks. These notifications are generated and delivered entirely on-device. No notification data is sent to any external server."),
        LegalSection(heading: "Third-Party Services", body: "Sova does not integrate with any third-party services, SDKs, or APIs. The only external service involved is Apple's iCloud, which is controlled by your Apple ID settings and governed by Apple's privacy policy."),
        LegalSection(heading: "Children's Privacy", body: "Sova is not directed at children under 13 and does not knowingly collect information from children. Since we do not collect any data from any user, this is inherently satisfied."),
        LegalSection(heading: "Data Deletion", body: "Since all data is stored locally on your device and in your private iCloud account, you have full control over your data at all times. To delete your data, simply delete the app from your device. To remove iCloud data, go to Settings > Apple ID > iCloud > Manage Storage > Sova and delete the data."),
        LegalSection(heading: "Changes to This Policy", body: "If we update this policy, we will post the revised version at this URL and update the \"Last Updated\" date. Continued use of the app after changes constitutes acceptance of the updated policy."),
        LegalSection(heading: "Contact", body: "If you have questions about this privacy policy, contact us at:\nhello@unlogged.is"),
    ]

    static let termsOfUse: [LegalSection] = [
        LegalSection(heading: nil, body: "These Terms of Use (\"Terms\") govern your use of the Sova application (\"the App\") developed by unlogged LLC (\"we,\" \"our,\" or \"us\"). By downloading or using the App, you agree to these Terms."),
        LegalSection(heading: "1. License", body: "We grant you a limited, non-exclusive, non-transferable, revocable license to use the App on any Apple device you own or control, subject to Apple's Usage Rules in the App Store Terms of Service."),
        LegalSection(heading: "2. Description of Service", body: "Sova is a personal maintenance tracker for items you own. The App allows you to log items, set maintenance schedules, store photos of receipts and warranties, and receive reminders. The App is a personal organizational tool and does not provide professional maintenance, mechanical, or engineering advice."),
        LegalSection(heading: "3. Subscriptions", body: "Sova offers a free tier and an optional paid subscription (\"Sova Pro\").\n\nPayment: Subscriptions are billed through your Apple ID account. Payment is charged at confirmation of purchase.\n\nRenewal: Subscriptions automatically renew unless canceled at least 24 hours before the end of the current billing period. Your account will be charged for renewal within 24 hours prior to the end of the current period.\n\nCancellation: You can manage and cancel subscriptions in your Apple ID Account Settings. Cancellation takes effect at the end of the current billing period. No refunds are provided for partial billing periods.\n\nPrice changes: We may change subscription pricing. You will be notified in advance and given the opportunity to cancel before new pricing takes effect.\n\nFree tier: The free tier provides access to a limited number of items and core features. Free tier functionality may change over time, but we will not remove items you have already created."),
        LegalSection(heading: "4. Your Data", body: "You own all data you enter into Sova. We do not claim any rights to your content. Since all data is stored locally and in your private iCloud account, you are responsible for maintaining backups. We are not responsible for data loss due to device failure, iCloud issues, or app deletion."),
        LegalSection(heading: "5. Acceptable Use", body: "You agree to use the App only for its intended personal organizational purpose and in compliance with applicable laws. You agree not to reverse engineer, decompile, or attempt to extract the source code of the App."),
        LegalSection(heading: "6. Intellectual Property", body: "The App, including its design, code, brand elements, and content, is owned by unlogged LLC and protected by copyright and other intellectual property laws. The Sova name, logo, and owl icon are trademarks of unlogged LLC."),
        LegalSection(heading: "7. Disclaimer of Warranties", body: "THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.\n\nWe do not warrant that the App will be uninterrupted, error-free, or free of harmful components. We do not warrant that maintenance reminders will be accurate, timely, or appropriate for your specific items or circumstances."),
        LegalSection(heading: "8. Limitation of Liability", body: "TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL UNLOGGED LLC BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF PROFITS, DATA, USE, OR GOODWILL, ARISING OUT OF OR IN CONNECTION WITH YOUR USE OF THE APP.\n\nThis includes, without limitation, any damages resulting from missed or incorrect maintenance reminders, equipment failure, property damage, voided warranties, or personal injury related to maintenance activities performed or not performed based on information provided by the App.\n\nOUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID FOR THE APP IN THE TWELVE (12) MONTHS PRECEDING THE CLAIM."),
        LegalSection(heading: "9. Indemnification", body: "You agree to indemnify and hold harmless unlogged LLC from any claims, damages, losses, or expenses arising from your use of the App or violation of these Terms."),
        LegalSection(heading: "10. Changes to Terms", body: "We may update these Terms from time to time. We will notify you of material changes through the App or by updating the \"Last Updated\" date. Continued use after changes constitutes acceptance."),
        LegalSection(heading: "11. Termination", body: "We may terminate or suspend your access to the App at any time, without notice, for conduct that we believe violates these Terms or is harmful to other users or us. Upon termination, your license to use the App is revoked."),
        LegalSection(heading: "12. Governing Law", body: "These Terms are governed by the laws of [Your State/Province, Country], without regard to conflict of law principles."),
        LegalSection(heading: "13. Contact", body: "For questions about these Terms, contact us at:\nhello@unlogged.is"),
    ]

    static let disclaimer: [LegalSection] = [
        LegalSection(heading: nil, body: "Sova is a personal organizational tool designed to help you track maintenance schedules for items you own. Please read the following carefully:"),
        LegalSection(heading: "Not professional advice", body: "Sova does not provide professional mechanical, engineering, structural, electrical, or maintenance advice. Maintenance schedules and reminders in the App are based on information you enter or general guidelines. They are not a substitute for your item's owner's manual, manufacturer recommendations, or the advice of a qualified professional."),
        LegalSection(heading: "Your responsibility", body: "You are solely responsible for the care and maintenance of your property. Sova is a reminder tool, not an authority on when or how maintenance should be performed. Always verify maintenance intervals with your owner's manual or a qualified technician before relying on any schedule set in the App."),
        LegalSection(heading: "No guarantee of accuracy", body: "We make no guarantees that the App's reminders, schedules, or notifications will be accurate, timely, or complete. Software may contain bugs, notifications may fail to deliver, and schedules may not account for your specific usage patterns, environmental conditions, or manufacturer updates."),
        LegalSection(heading: "No liability for damages", body: "We are not liable for any property damage, equipment failure, voided warranties, personal injury, financial loss, or any other damages resulting from maintenance performed or not performed based on information provided by the App. This includes, but is not limited to:\n\n- Missed maintenance due to failed notifications or incorrect schedules\n- Equipment damage from following general maintenance intervals that were not appropriate for your specific item or usage\n- Warranty claims denied because maintenance was not performed according to manufacturer specifications\n- Costs incurred from unnecessary maintenance performed based on App reminders"),
        LegalSection(heading: "Warranty information", body: "Warranty details stored in Sova are entered by you for your personal reference. We do not verify warranty terms, coverage, or expiration dates. Always refer to your original warranty documentation and contact the manufacturer or seller directly for warranty claims."),
        LegalSection(heading: "Receipt storage", body: "Receipts and photos stored in Sova are for your personal organizational convenience. We do not guarantee the preservation, quality, or legality of stored receipt images as proof of purchase. Always retain original receipts and documentation for important purchases, warranty claims, and tax purposes."),
        LegalSection(heading: "Vehicle-specific notice", body: "Sova is not a diagnostic tool and cannot detect mechanical issues, safety hazards, or recall notices. Always follow your vehicle manufacturer's recommended maintenance schedule, respond to dashboard warning indicators, and have your vehicle inspected by a certified mechanic at regular intervals regardless of what Sova indicates."),
        LegalSection(heading: "Use at your own risk", body: "By using Sova, you acknowledge that maintenance decisions are ultimately your responsibility and that the App is provided as a convenience tool, not as an authoritative source of maintenance guidance."),
    ]
}
// swiftlint:enable line_length
