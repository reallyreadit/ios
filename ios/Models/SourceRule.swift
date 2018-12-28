import Foundation

struct SourceRule: Codable {
    let id: Int
    let hostname: String
    let path: String
    let priority: Int
    let action: SourceRuleAction
}
