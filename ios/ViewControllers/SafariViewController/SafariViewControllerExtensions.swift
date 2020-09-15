import Foundation
import UIKit
import SafariServices

extension UIViewController {
    func presentSafariViewController(
        url: URL,
        theme: DisplayTheme
    ) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            safariViewController.overrideUserInterfaceStyle = (
                theme == .dark ?
                    .dark :
                    .light
            )
        }
        present(safariViewController, animated: true)
    }
}
