import Foundation
import UIKit
import SafariServices

class DisposableSafariViewControllerDelegate : NSObject, SFSafariViewControllerDelegate {
    private var completionHandler: (() -> Void)?
    init(_ completionHandler: @escaping () -> Void) {
        super.init()
        self.completionHandler = {
            completionHandler()
            self.completionHandler = nil
        }
    }
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.completionHandler?()
    }
}

extension UIViewController {
    func presentSafariViewController(
        url: URL,
        theme: DisplayTheme,
        completionHandler: (() -> Void)?
    ) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .overCurrentContext
        if let completionHandler = completionHandler {
            let delegate = DisposableSafariViewControllerDelegate(completionHandler)
            safariViewController.delegate = delegate
        }
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
