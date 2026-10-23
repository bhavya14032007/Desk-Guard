import Foundation
import Supabase

/// Central singleton holding the configured Supabase client.
/// Reads credentials dynamically from Info.plist (injected via Config.xcconfig).
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient
    let isConfigured: Bool
    let configurationDiagnostic: String?

    private init() {
        // Read injected build settings from Info.plist
        let infoDict = Bundle.main.infoDictionary
        let rawURL = (infoDict?["SupabaseURL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawKey = (infoDict?["SupabasePublishableKey"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Validate that keys are not empty or left as unedited placeholder
        let isValidURL = !rawURL.isEmpty && rawURL.hasPrefix("http") && !rawURL.contains("your-project-id")
        let isValidKey = !rawKey.isEmpty && !rawKey.contains("your-anon-publishable-key")

        if isValidURL && isValidKey, let url = URL(string: rawURL) {
            self.client = SupabaseClient(supabaseURL: url, supabaseKey: rawKey)
            self.isConfigured = true
            self.configurationDiagnostic = nil
        } else {
            // Provide safe fallback client to prevent instant crash on launch if user forgot to edit Config.xcconfig
            let fallbackURL = URL(string: "https://fallback.supabase.co")!
            self.client = SupabaseClient(supabaseURL: fallbackURL, supabaseKey: "placeholder")
            self.isConfigured = false
            self.configurationDiagnostic = "Supabase URL or Publishable Key is not configured. Please edit ios/Config.xcconfig with your Supabase credentials."
        }
    }
}
