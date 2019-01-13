import Foundation

struct ReadStateCommitData: Codable {
    init(_ data: [String: Any]) {
        userPageId = data["userPageId"] as! Int
        readState = data["readState"] as! [Int]
    }
    var userPageId: Int
    var readState: [Int]
}
