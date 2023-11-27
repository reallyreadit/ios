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

struct SharedBundleInfo {
    public static let apiServerURL = URL(
        string: (Bundle.main.infoDictionary!["ReadupAPIServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
    public static let authCookieDomain = Bundle.main.infoDictionary!["ReadupAuthCookieDomain"] as! String
    public static let authCookieName = Bundle.main.infoDictionary!["ReadupAuthCookieName"] as! String
    public static let clientID = Bundle.main.infoDictionary!["ReadupClientID"] as! String
    public static let shareExtensionScript = WebViewScript(
        bundledVersion: SemanticVersion(
            fromVersionString: Bundle.main.infoDictionary!["ReadupShareExtensionScriptVersion"] as? String
        )!,
        name: "share-extension"
    )
    public static let version = SemanticVersion(
        fromVersionString: (
            Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        )
    )!
    public static let webServerURL = URL(
        string: (Bundle.main.infoDictionary!["ReadupWebServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
}
