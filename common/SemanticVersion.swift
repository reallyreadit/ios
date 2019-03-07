import Foundation

struct SemanticVersion {
    init?(fromFileName fileName: String?) {
        if fileName == nil {
            return nil
        }
        let versionRegex = try! NSRegularExpression(pattern: "\\d\\.\\d\\.\\d")
        if
            let match = versionRegex.firstMatch(
                in: fileName!,
                options: [],
                range: NSRange(
                    fileName!.startIndex...,
                    in: fileName!
                )
            ),
            let matchRange = Range(
                match.range,
                in: fileName!
            )
        {
            self.init(fromVersionString: String(fileName![matchRange]))
        } else {
            return nil
        }
    }
    init?(fromVersionString versionString: String?) {
        if versionString == nil {
            return nil
        }
        let parts = versionString!
            .split(separator: ".")
            .map({ string in Int(string) ?? -1 })
        if parts.count == 3 && parts.allSatisfy({ part in part >= 0 }) {
            major = parts[0]
            minor = parts[1]
            patch = parts[2]
            description = "\(major).\(minor).\(patch)"
        } else {
            return nil
        }
    }
    let description: String
    let major: Int
    let minor: Int
    let patch: Int
    func canUpgradeTo(_ version: SemanticVersion?) -> Bool {
        if let version = version {
            return (
                version.major == major &&
                (
                    version.minor > minor ||
                    (
                        version.minor == minor &&
                        version.patch > patch
                    )
                )
            )
        }
        return false
    }
}
