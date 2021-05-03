import Foundation
import UIKit
import os.log

extension UIViewController {
    func presentActivityViewController(
        data: ShareData,
        theme: DisplayTheme,
        completionHandler: @escaping (_: ShareResult) -> Void
    ) {
        os_log("[sharing] presenting UIActivityViewController")
        let activityViewController = UIActivityViewController(
            activityItems: [
                ShareDataURLSource(data),
                ShareDataStringSource(data)
            ],
            applicationActivities: nil
        )
        // this doesn't work for some reason but maybe it'll be fixed in future updates
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.init(rawValue: "it.reallyread.mobile.share-extension")
        ]
        activityViewController.completionWithItemsHandler = {
            activityType, completed, returnedItems, activityError in
            os_log("[sharing] activity type: %s, completed: %d", activityType?.rawValue ?? "", completed)
            if let error = activityError {
                os_log("[sharing] activity error: %s", error.localizedDescription)
            }
            let result = ShareResult(
                id: UUID(),
                action: data.action ?? "",
                activityType: activityType?.rawValue ?? "",
                completed: completed,
                error: activityError?.localizedDescription
            )
            completionHandler(result)
        }
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.popoverPresentationController?.sourceRect = CGRect(
            x: CGFloat(data.selection.x) * self.view.bounds.width,
            y: CGFloat(data.selection.y) * self.view.bounds.height,
            width: CGFloat(data.selection.width) * self.view.bounds.width,
            height: CGFloat(data.selection.height) * self.view.bounds.height
        )
        activityViewController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            activityViewController.overrideUserInterfaceStyle = (
                theme == .dark ?
                    .dark :
                    .light
            )
        }
        present(activityViewController, animated: true, completion: nil)
    }
}
