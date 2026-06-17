import Foundation

enum StreamFraming {
    static let maxFrameLength = 0xFFFF

    static func writeFrame(_ stream: ByteStream, _ payload: Data) throws {
        guard payload.count <= maxFrameLength else { throw TransportError.frameTooLarge }
        var framed = Data([UInt8((payload.count >> 8) & 0xFF), UInt8(payload.count & 0xFF)])
        framed.append(payload)
        try stream.write(framed)
    }

    static func readFrame(_ stream: ByteStream) throws -> Data {
        let header = [UInt8](try stream.readExact(2))
        let length = (Int(header[0]) << 8) | Int(header[1])
        return try stream.readExact(length)
    }
}
