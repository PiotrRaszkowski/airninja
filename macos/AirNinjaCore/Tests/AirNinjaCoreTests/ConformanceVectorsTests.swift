import XCTest
import AirNinjaCore

final class ConformanceVectorsTests: XCTestCase {

    func testDeviceIdVectorsMatch() throws {
        let cases = try vectors()["deviceId"] as! [[String: Any]]
        for entry in cases {
            let publicKey = TestHex.decode(entry["staticPubKeyHex"] as! String)
            XCTAssertEqual(DeviceId.fromPublicKey(publicKey), entry["deviceId"] as! String)
        }
    }

    func testFrameEncodingVectorsMatch() throws {
        let cases = try vectors()["frameEncoding"] as! [[String: Any]]
        for entry in cases {
            let frame: Frame
            switch entry["frameType"] as! String {
            case "CONTROL":
                frame = .control(payload: Data((entry["payloadUtf8"] as! String).utf8))
            case "DATA":
                frame = .data(
                    streamId: UInt32(entry["streamId"] as! Int),
                    sequence: UInt64(entry["seq"] as! Int),
                    isFinal: entry["final"] as! Bool,
                    chunk: Data((entry["chunkUtf8"] as! String).utf8)
                )
            default:
                XCTFail("Unknown frame type")
                return
            }
            XCTAssertEqual(TestHex.encode(FrameCodec.encode(frame)), entry["frameHex"] as! String)
        }
    }

    func testSasDerivationVectorsMatch() throws {
        let cases = try vectors()["sasDerivation"] as! [[String: Any]]
        for entry in cases {
            let handshakeHash = TestHex.decode(entry["handshakeHashHex"] as! String)
            XCTAssertEqual(Sas.derive(handshakeHash: handshakeHash), entry["sas"] as! String)
        }
    }

    private func vectors() throws -> [String: Any] {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<8 {
            url.deleteLastPathComponent()
            let candidate = url.appendingPathComponent("shared/conformance/vectors.json")
            if FileManager.default.fileExists(atPath: candidate.path) {
                let data = try Data(contentsOf: candidate)
                return try JSONSerialization.jsonObject(with: data) as! [String: Any]
            }
        }
        throw XCTSkip("Conformance vectors.json not found")
    }
}
