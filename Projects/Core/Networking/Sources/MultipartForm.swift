import Foundation

/// `multipart/form-data` 본문 (RFC 7578).
public struct MultipartForm: Sendable {
    private enum Part: Sendable {
        case field(name: String, value: String)
        case file(name: String, fileName: String, mimeType: String, data: Data)
    }

    public let boundary: String
    private var parts: [Part] = []

    public init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }

    public var contentType: String {
        return "multipart/form-data; boundary=\(boundary)"
    }

    public mutating func addField(name: String, value: String) {
        parts.append(.field(name: name, value: value))
    }

    public mutating func addFile(name: String, fileName: String, mimeType: String, data: Data) {
        parts.append(.file(name: name, fileName: fileName, mimeType: mimeType, data: data))
    }

    public func encoded() -> Data {
        var body = Data()
        for part in parts {
            body.append("--\(boundary)\r\n")
            switch part {
            case .field(let name, let value):
                body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
                body.append(value)
            case .file(let name, let fileName, let mimeType, let data):
                body.append(
                    "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"
                )
                body.append("Content-Type: \(mimeType)\r\n\r\n")
                body.append(data)
            }
            body.append("\r\n")
        }
        body.append("--\(boundary)--\r\n")
        return body
    }
}

extension Data {
    fileprivate mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
