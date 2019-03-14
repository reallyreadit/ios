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
        if (activityType == .mail) {
            return data.email.body
        }
        if (activityType == .postToTwitter) {
            let limit = 280 - 25
            return (
                data.text.count > limit ?
                    String(data.text.prefix(limit - 3) + "...") :
                    data.text
            )
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
