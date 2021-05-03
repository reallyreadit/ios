import Foundation

struct ShareSelection: Codable {
    init(_ data: [String: Any]) {
        x = data["x"] as! Double
        y = data["y"] as! Double
        width = data["width"] as! Double
        height = data["height"] as! Double
    }
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}
