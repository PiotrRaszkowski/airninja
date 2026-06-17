import Foundation

public enum FrameCodecError: Error, Equatable {
    case frameTooShort
    case lengthMismatch
    case tooLong
    case unknownType(Int)
    case truncated
}

public enum FrameCodec {
    public static let typeControl: UInt8 = 0x01
    public static let typeData: UInt8 = 0x02
    public static let maxFrameLength = 1 << 20

    private static let lengthField = 4
    private static let typeField = 1
    private static let streamIdField = 4
    private static let sequenceField = 8
    private static let flagsField = 1
    private static let flagFinal: UInt8 = 0x01

    public static func encode(_ frame: Frame) -> Data {
        switch frame {
        case .control(let payload):
            return encodeBody(type: typeControl, body: payload)
        case .data(let streamId, let sequence, let isFinal, let chunk):
            return encodeBody(type: typeData, body: encodeDataSubHeader(streamId, sequence, isFinal, chunk))
        }
    }

    public static func decode(_ frame: Data) throws -> Frame {
        let bytes = [UInt8](frame)
        guard bytes.count >= lengthField + typeField else { throw FrameCodecError.frameTooShort }
        let declaredLength = readBE32(bytes, at: 0)
        guard Int(declaredLength) == bytes.count - lengthField else { throw FrameCodecError.lengthMismatch }
        guard Int(declaredLength) <= maxFrameLength else { throw FrameCodecError.tooLong }
        let type = bytes[lengthField]
        let bodyStart = lengthField + typeField
        switch type {
        case typeControl:
            return .control(payload: Data(bytes[bodyStart...]))
        case typeData:
            return try decodeData(Array(bytes[bodyStart...]))
        default:
            throw FrameCodecError.unknownType(Int(type))
        }
    }

    private static func encodeBody(type: UInt8, body: Data) -> Data {
        let length = typeField + body.count
        var out = Data()
        appendBE32(UInt32(length), to: &out)
        out.append(type)
        out.append(body)
        return out
    }

    private static func encodeDataSubHeader(_ streamId: UInt32, _ sequence: UInt64, _ isFinal: Bool, _ chunk: Data) -> Data {
        var sub = Data()
        appendBE32(streamId, to: &sub)
        appendBE64(sequence, to: &sub)
        sub.append(isFinal ? flagFinal : 0)
        sub.append(chunk)
        return sub
    }

    private static func decodeData(_ sub: [UInt8]) throws -> Frame {
        guard sub.count >= streamIdField + sequenceField + flagsField else { throw FrameCodecError.truncated }
        let streamId = readBE32(sub, at: 0)
        let sequence = readBE64(sub, at: streamIdField)
        let flags = sub[streamIdField + sequenceField]
        let isFinal = (flags & flagFinal) == flagFinal
        let chunk = Data(sub[(streamIdField + sequenceField + flagsField)...])
        return .data(streamId: streamId, sequence: sequence, isFinal: isFinal, chunk: chunk)
    }

    private static func appendBE32(_ value: UInt32, to data: inout Data) {
        data.append(UInt8((value >> 24) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8(value & 0xFF))
    }

    private static func appendBE64(_ value: UInt64, to data: inout Data) {
        for shift in stride(from: 56, through: 0, by: -8) {
            data.append(UInt8((value >> UInt64(shift)) & 0xFF))
        }
    }

    private static func readBE32(_ bytes: [UInt8], at offset: Int) -> UInt32 {
        var value: UInt32 = 0
        for index in 0..<4 {
            value = (value << 8) | UInt32(bytes[offset + index])
        }
        return value
    }

    private static func readBE64(_ bytes: [UInt8], at offset: Int) -> UInt64 {
        var value: UInt64 = 0
        for index in 0..<8 {
            value = (value << 8) | UInt64(bytes[offset + index])
        }
        return value
    }
}
