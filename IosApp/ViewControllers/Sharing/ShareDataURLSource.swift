import Foundation
import UIKit

class ShareDataURLSource: NSObject, UIActivityItemSource {
    private let data: ShareData
    init(_ data: ShareData) {
        self.data = data
    }
    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        return data.url
    }
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        if (activityType == .mail) {
            return nil
        }
        return data.url
    }
}
