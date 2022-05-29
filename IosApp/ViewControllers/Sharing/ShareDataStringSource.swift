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
import UIKit

class ShareDataStringSource: NSObject, UIActivityItemSource {
    private let data: ShareData
    init(_ data: ShareData) {
        self.data = data
    }
    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        return data.text
    }
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        if (activityType == .copyToPasteboard || activityType == .message) {
            return nil
        }
        if (activityType == .mail) {
            return data.email.body
        }
        if (activityType == .postToTwitter) {
            let limit = 280 - 25 - 32
            let tweetText = (
                data.text.count > limit ?
                    String(data.text.prefix(limit - 3) + "...") :
                    data.text
            )
            return tweetText + " #ReadOnReadup via @ReadupDotCom"
        }
        return data.text
    }
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return data.email.subject
    }
}
