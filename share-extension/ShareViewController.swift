import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        print("didSelectPost()")
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.sharedCookieStorage(
            forGroupContainerIdentifier: "group.it.reallyread"
        )
        URLSession(configuration: config)
            .dataTask(
                with: URLRequest(
                    url: URL(string: "http://api.dev.reallyread.it/HealthCheck/Check")!
                ),
                completionHandler: {
                    data, response, error in
                    if
                        error == nil,
                        let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode)
                    {
                        print("OK")
                    } else {
                        print("Bad request")
                    }
                    self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                }
            )
            .resume()
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
