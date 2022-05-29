// Copyright (C) 2022 reallyread.it, inc.
// 
// This file is part of Readup.
// 
// Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
// 
// Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

import SafariServices
import os.log

let SFExtensionMessageKey = "message"

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

	func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems[0] as! NSExtensionItem
        let message = item.userInfo?[SFExtensionMessageKey] as! [AnyHashable: Any]
        let messageData = message["data"] as! [String: Any]
        
        var readupAppURL = URLComponents(string: "readup://read")!
        readupAppURL.queryItems = [
            URLQueryItem(name: "url", value: messageData["url"] as? String)
        ]
        if (messageData["star"] as! Bool) {
            readupAppURL.queryItems!.append(
                URLQueryItem(name: "star", value: nil)
            )
        }
        
        NSWorkspace.shared.open(
            readupAppURL.url!,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: {
                app, error in
                var outgoingMessage: [String: Any] = [
                    "version": "1.0.0"
                ]
                if (app != nil) {
                    outgoingMessage["succeeded"] = true
                } else {
                    outgoingMessage["succeeded"] = false
                    outgoingMessage["error"] = [
                        "title": "Failed to launch Readup app using custom protocol.",
                        "type": BrowserExtensionAppErrorType.readupProtocolFailed.rawValue
                    ]
                }
                let response = NSExtensionItem()
                response.userInfo = [
                    SFExtensionMessageKey: outgoingMessage
                ]
                context.completeRequest(returningItems: [response], completionHandler: nil)
            }
        )
    }
    
}
