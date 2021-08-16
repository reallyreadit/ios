import Foundation
import AppKit

enum IncomingMessage : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "readArticle":
            self = .readArticle(
                try container.decode(ReadArticleMessageData.self, forKey: .data)
            )
        default:
            self = .unknown(type)
        }
    }
    
    case
        readArticle(ReadArticleMessageData),
        unknown(String)
    
    enum CodingKeys: CodingKey {
        case
            type,
            data
    }
}

struct ReadArticleMessageData : Decodable {
    let url: URL
}

struct OutgoingMessage : Encodable {
    let version: String
    let succeeded: Bool
    let error: ProblemDetails?
}

func sendResponse(message: OutgoingMessage) {
    let encoder = JSONEncoder()
    let outgoingMessage = try! encoder.encode(message)
    var outgoingMessageData = withUnsafeBytes(
        of: Int32(outgoingMessage.count),
        {
            pointer in
            Data(pointer)
        }
    )
    outgoingMessageData.append(outgoingMessage)
    FileHandle.standardOutput.write(outgoingMessageData)
}

func sendSuccessResponse() {
    sendResponse(
        message: OutgoingMessage(
            version: appVersion,
            succeeded: true,
            error: nil
        )
    )
}

func sendErrorResponse(error: ProblemDetails) {
    sendResponse(
        message: OutgoingMessage(
            version: appVersion,
            succeeded: false,
            error: error
        )
    )
}

let appVersion = "1.0.0"

let incomingMessageSize = FileHandle.standardInput
    .readData(ofLength: 4)
    .withUnsafeBytes({
        pointer in
        pointer.load(as: Int32.self)
    })

let decoder = JSONDecoder()

guard
    let incomingMessage = try? decoder.decode(
        IncomingMessage.self,
        from: FileHandle.standardInput.readData(ofLength: Int(incomingMessageSize))
    )
else {
    sendErrorResponse(
        error: ProblemDetails(
            type: BrowserExtensionAppErrorType.messageParsingFailed,
            title: "Failed to parse incoming message."
        )
    )
    exit(EXIT_SUCCESS)
}

switch (incomingMessage) {
case .readArticle(let readArticleData):
    // Build the url using the Readup protocol to launch the main app.
    var readupAppURL = URLComponents(string: "readup://read")!
    readupAppURL.queryItems = [
        URLQueryItem(name: "url", value: readArticleData.url.absoluteString)
    ]
    // Attempt to open the app asynchronously.
    NSWorkspace.shared.open(
        readupAppURL.url!,
        configuration: NSWorkspace.OpenConfiguration(),
        completionHandler: {
            app, error in
            if app != nil {
                sendSuccessResponse()
            } else {
                sendErrorResponse(
                    error: ProblemDetails(
                        type: BrowserExtensionAppErrorType.readupProtocolFailed,
                        title: "Failed to launch Readup app using custom protocol."
                    )
                )
            }
            exit(EXIT_SUCCESS)
        }
    )
    dispatchMain()
case .unknown(let messageType):
    sendErrorResponse(
        error: ProblemDetails(
            type: BrowserExtensionAppErrorType.unexpectedMessageType,
            title: "Unexpected message type: \(messageType)."
        )
    )
}
