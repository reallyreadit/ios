// Copyright (C) 2022 reallyread.it, inc.
// 
// This file is part of Readup.
// 
// Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
// 
// Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

import Foundation

struct SemanticVersion {
    static func greatest(_ version: SemanticVersion, _ otherVersions: SemanticVersion?...) -> SemanticVersion {
        return ([version] + otherVersions.compactMap({ $0 }))
            .sorted(by: { a, b in a.compareTo(b) < 0 })
            .last!
    }
    init?(fromFileName fileName: String?) {
        if fileName == nil {
            return nil
        }
        let versionRegex = try! NSRegularExpression(pattern: "\\d+\\.\\d+\\.\\d+")
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
        /**
         I accidentally assigned a new version in AppStoreConnect using only the major and minor parts.
         This caused an app crash when trying to parse the version string from the bundle plist, which must
         get overwritten during processing with the version supplied in the web interface. There is no way to
         change the version in AppStoreConnect so for now at least we must be forgiving when parsing version
         numbers.
         */
        if 1...3 ~= parts.count && parts.allSatisfy({ part in part >= 0 }) {
            major = parts[0]
            minor = parts.count > 1 ? parts[1] : 0
            patch = parts.count > 2 ? parts[2] : 0
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
    func compareTo(_ version: SemanticVersion) -> Int {
        if (self.major != version.major) {
            return self.major - version.major;
        }
        if (self.minor != version.minor) {
            return self.minor - version.minor;
        }
        if (self.patch != version.patch) {
            return self.patch - version.patch;
        }
        return 0;
    }
}
