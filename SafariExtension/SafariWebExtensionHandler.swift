import SafariServices
import os.log

let SFExtensionMessageKey = "message"

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

	func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems[0] as! NSExtensionItem
        let message = item.userInfo?[SFExtensionMessageKey] as! [String: String]
        
        var readupAppURL = URLComponents(string: "readup://read")!
        readupAppURL.queryItems = [
            URLQueryItem(name: "url", value: message["url"])
        ]
        
        NSWorkspace.shared.open(
            readupAppURL.url!,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: {
                app, error in
                let response = NSExtensionItem()
                response.userInfo = [
                    SFExtensionMessageKey: [
                        "status": app != nil ? 0 : 1
                    ]
                ]
                context.completeRequest(returningItems: [response], completionHandler: nil)
            }
        )
    }
    
}
