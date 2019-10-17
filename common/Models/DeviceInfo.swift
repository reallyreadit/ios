import Foundation

struct DeviceInfo: Codable {
    let appVersion: String
    let installationId: String?
    let name: String
    let token: String?
}
