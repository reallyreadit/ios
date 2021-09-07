import Foundation

enum AppPlatform : String, Codable {
    case
        android = "Android",
        iOS = "iOS",
        linux = "Linux",
        macOS = "macOS",
        windows = "Windows"
}

func getAppPlatform() -> AppPlatform {
    #if targetEnvironment(macCatalyst)
    return .macOS
    #else
    return .iOS
    #endif
}
