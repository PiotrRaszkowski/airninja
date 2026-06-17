import XCTest
import AirNinjaCore

final class IdentityTests: XCTestCase {

    func testDeviceIdFromKnownKeyMatchesExpected() {
        let publicKey = TestHex.decode("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
        XCTAssertEqual(DeviceId.fromPublicKey(publicKey), "mmg42klgyqzwneiskrelxms3j72bfje4omw3fsflyg4fqg6xcdoq")
    }

    func testGenerateProducesThirtyTwoByteKeysAndDeviceId() {
        let identity = DeviceIdentity.generate()
        XCTAssertEqual(identity.publicKey.count, 32)
        XCTAssertEqual(identity.privateKey.count, 32)
        XCTAssertEqual(identity.deviceId.count, 52)
    }

    func testGenerateProducesDistinctIdentities() {
        XCTAssertNotEqual(DeviceIdentity.generate().deviceId, DeviceIdentity.generate().deviceId)
    }

    func testFromRawKeysWithWrongPrivateKeySizeThrows() {
        XCTAssertThrowsError(try DeviceIdentity.fromRawKeys(privateKey: Data(count: 16), publicKey: Data(count: 32))) {
            XCTAssertEqual($0 as? DeviceIdentityError, .invalidKeyLength)
        }
    }
}
