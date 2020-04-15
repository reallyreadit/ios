import Foundation

struct LeaderboardBadge: OptionSet, Codable {
    let rawValue: Int
    
    static let none = LeaderboardBadge([])
    static let longestRead = LeaderboardBadge(rawValue: 1 << 0)
    static let readCount = LeaderboardBadge(rawValue: 1 << 1)
    static let scout = LeaderboardBadge(rawValue: 1 << 2)
    static let scribe = LeaderboardBadge(rawValue: 1 << 3)
    static let streak = LeaderboardBadge(rawValue: 1 << 4)
    static let weeklyReadCount = LeaderboardBadge(rawValue: 1 << 5)
}
