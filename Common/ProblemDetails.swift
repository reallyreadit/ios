import Foundation

class ProblemDetails: Error, Codable {
    init(detail: String) {
        self.detail = detail
        instance = nil
        title = "A general exception occurred."
        type = GeneralErrorType.exception.rawValue
    }
    convenience init(_ error: Error) {
        self.init(detail: error.localizedDescription)
    }
    init<T: RawRepresentable> (
        type: T,
        title: String,
        detail: String? = nil,
        instance: String? = nil
    )
        where T.RawValue == String
    {
        self.detail = detail
        self.instance = instance
        self.title = title
        self.type = type.rawValue
    }
    let detail: String?
    let instance: String?
    let title: String
    let type: String
    
    func isOfType<T: RawRepresentable>(_ type: T) -> Bool where T.RawValue == String {
        return self.type == type.rawValue
    }
}

class HTTPProblemDetails: ProblemDetails {
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(Int.self, forKey: .status)
        traceId = try container.decode(String.self, forKey: .traceId)
        try super.init(from: decoder)
    }
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encode(traceId, forKey: .traceId)
        try super.encode(to: encoder)
    }
    
    let status: Int
    let traceId: String
    
    enum CodingKeys: CodingKey {
        case
            status,
            traceId
    }
}
