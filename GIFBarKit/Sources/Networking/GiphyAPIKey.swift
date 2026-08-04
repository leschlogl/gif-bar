import Foundation

/// Reads the Giphy API key injected into `Info.plist` at build time from
/// `Config/Secrets.xcconfig`. Only meaningful inside the app bundle — unit tests
/// (which run outside any app bundle) should inject a key directly instead.
public enum GiphyAPIKey {
    public static func fromMainBundle() -> String? {
        Bundle.main.infoDictionary?["GiphyAPIKey"] as? String
    }
}
