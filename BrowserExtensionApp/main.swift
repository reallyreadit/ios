import Foundation
import AppKit

struct IncomingMessage : Decodable {
    let url: String
}

struct OutgoingMessage : Encodable {
    let status: Int
}

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
    exit(EXIT_FAILURE)
}

var readupAppURL = URLComponents(string: "readup://read")!
readupAppURL.queryItems = [
    URLQueryItem(name: "url", value: incomingMessage.url)
]

let encoder = JSONEncoder()

NSWorkspace.shared.open(
    readupAppURL.url!,
    configuration: NSWorkspace.OpenConfiguration(),
    completionHandler: {
        app, error in
        let outgoingMessage = try! encoder.encode(
            OutgoingMessage(status: app != nil ? 0 : 1)
        )
        var outgoingMessageData = withUnsafeBytes(
            of: Int32(outgoingMessage.count),
            {
                pointer in
                Data(pointer)
            }
        )
        outgoingMessageData.append(outgoingMessage)
        FileHandle.standardOutput.write(outgoingMessageData)
        exit(EXIT_SUCCESS)
    }
)

dispatchMain()
