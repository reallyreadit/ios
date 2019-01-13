import Foundation

struct CommitReadStateEvent: Codable {
    init(_ data: [String: Any]) {
        commitData = ReadStateCommitData(data["commitData"] as! [String: Any])
        isCompletionCommit = data["isCompletionCommit"] as! Bool
    }
    let commitData: ReadStateCommitData
    let isCompletionCommit: Bool
}
