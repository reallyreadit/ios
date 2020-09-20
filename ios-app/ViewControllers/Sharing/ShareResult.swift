import Foundation

struct ShareResult: Codable {
    let id: UUID
    let action: String
    let activityType: String
    let completed: Bool
    let error: String?
}
