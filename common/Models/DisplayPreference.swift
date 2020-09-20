import Foundation

struct DisplayPreference: Codable, Equatable {
    init?(serializedPreference: [String: Any]) {
        hideLinks = serializedPreference["hideLinks"] as! Bool
        textSize = serializedPreference["textSize"] as! Int
        theme = DisplayTheme.init(rawValue: serializedPreference["theme"] as! Int)!
    }
    let hideLinks: Bool
    let textSize: Int
    let theme: DisplayTheme
}
