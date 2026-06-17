import XCTest
import AirNinjaCore

final class FrameCodecTests: XCTestCase {

    func testEncodeControlFrameProducesLengthPrefixedFrame() {
        let encoded = FrameCodec.encode(.control(payload: Data("hi".utf8)))
        XCTAssertEqual(TestHex.encode(encoded), "00000003016869")
    }

    func testEncodeDataFrameProducesSubHeaderAndChunk() {
        let encoded = FrameCodec.encode(.data(streamId: 1001, sequence: 1, isFinal: true, chunk: Data("hello".utf8)))
        XCTAssertEqual(TestHex.encode(encoded), "0000001302000003e900000000000000010168656c6c6f")
    }

    func testDecodeControlFrameRoundTripsPayload() throws {
        let payload = Data("round-trip".utf8)
        let decoded = try FrameCodec.decode(FrameCodec.encode(.control(payload: payload)))
        XCTAssertEqual(decoded, .control(payload: payload))
    }

    func testDecodeDataFrameRoundTripsAllFields() throws {
        let original = Frame.data(streamId: 42, sequence: 7, isFinal: false, chunk: Data([1, 2, 3]))
        let decoded = try FrameCodec.decode(FrameCodec.encode(original))
        XCTAssertEqual(decoded, original)
    }

    func testDecodeWrongLengthPrefixThrows() {
        XCTAssertThrowsError(try FrameCodec.decode(TestHex.decode("00000099016869"))) {
            XCTAssertEqual($0 as? FrameCodecError, .lengthMismatch)
        }
    }

    func testDecodeUnknownFrameTypeThrows() {
        XCTAssertThrowsError(try FrameCodec.decode(TestHex.decode("000000017f"))) {
            XCTAssertEqual($0 as? FrameCodecError, .unknownType(0x7f))
        }
    }
}
