import Foundation
import UIKit
import SafariServices

extension UIViewController {
    func presentSafariViewController(
        url: URL,
        delegate: SFSafariViewControllerDelegate
    ) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.delegate = delegate
        present(safariViewController, animated: true)
    }
}
