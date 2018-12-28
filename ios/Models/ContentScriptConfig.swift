import Foundation

struct ContentScriptConfig: Codable {
    let idleReadRate: Int
    let pageOffsetUpdateRate: Int
    let readStateCommitRate: Int
    let readWordRate: Int
}
