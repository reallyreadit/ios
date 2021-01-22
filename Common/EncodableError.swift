class EncodableError: Encodable, Error {
    init(message: String?) {
        self.message = message
    }
    let message: String?
}
class EnumError<T: RawRepresentable>: EncodableError where T.RawValue == Int {
    enum CodingKeys: String, CodingKey {
        case
            value = "value"
    }
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let value = value {
            try container.encode(value.rawValue, forKey: .value)
        }
        try super.encode(to: encoder)
    }
    init(value: T) {
        self.value = value
        super.init(message: nil)
    }
    init(message: String) {
        self.value = nil
        super.init(message: message)
    }
    let value: T?
}
