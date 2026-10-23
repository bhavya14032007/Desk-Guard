import Foundation
import Supabase

/// Central singleton holding the configured Supabase client.
/// Reads credentials dynamically from Info.plist, environment, or safe project defaults.
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient
    let isConfigured: Bool
    let configurationDiagnostic: String?

    // Default project credentials deployed for Desk Guard
    static let defaultURLString = "https://fcczltrhweqvqspdzoyi.supabase.co"
    static let defaultPublishableKey = "sb_publishable_s-a_prjaV_uPopwunebQ4A_fPRm5x8l"

    private init() {
        let infoDict = Bundle.main.infoDictionary
        let env = ProcessInfo.processInfo.environment

        // 1. Try Info.plist / xcconfig keys
        var resolvedURL = (infoDict?["SupabaseURL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? (infoDict?["NEXT_PUBLIC_SUPABASE_URL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? env["SUPABASE_URL"]
            ?? ""

        var resolvedKey = (infoDict?["SupabasePublishableKey"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? (infoDict?["NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? env["SUPABASE_PUBLISHABLE_KEY"]
            ?? ""

        // 2. Validate and fallback to active project credentials
        if resolvedURL.isEmpty || resolvedURL.contains("your-project-id") || !resolvedURL.hasPrefix("http") {
            resolvedURL = SupabaseManager.defaultURLString
        }

        if resolvedKey.isEmpty || resolvedKey.contains("your-anon-publishable-key") {
            resolvedKey = SupabaseManager.defaultPublishableKey
        }

        if let url = URL(string: resolvedURL), !resolvedKey.isEmpty {
            self.client = SupabaseClient(supabaseURL: url, supabaseKey: resolvedKey)
            self.isConfigured = true
            self.configurationDiagnostic = nil
        } else {
            let fallbackURL = URL(string: SupabaseManager.defaultURLString)!
            self.client = SupabaseClient(supabaseURL: fallbackURL, supabaseKey: SupabaseManager.defaultPublishableKey)
            self.isConfigured = true
            self.configurationDiagnostic = nil
        }
    }
}
