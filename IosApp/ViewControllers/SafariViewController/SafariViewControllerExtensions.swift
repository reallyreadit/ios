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
