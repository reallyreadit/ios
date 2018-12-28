import Foundation

struct ContentScriptInitData: Codable {
    let config: ContentScriptConfig
    let loadPage: Bool
    let parseMetadata: Bool
    let parseMode: String
    let showOverlay: Bool
    let sourceRules: [SourceRule]
}
