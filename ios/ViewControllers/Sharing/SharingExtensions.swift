import Foundation
import UIKit

extension UIViewController {
    func presentActivityViewController(data: ShareData) {
        let activityViewController = UIActivityViewController(
            activityItems: [
                ShareDataURLSource(data),
                ShareDataStringSource(data),
                ShareBlockerSource()
            ],
            applicationActivities: nil
        )
        activityViewController.popoverPresentationController?.sourceView = self.view
        present(activityViewController, animated: true, completion: nil)
    }
}
