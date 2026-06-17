import Foundation
import AirNinjaCore

#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

final class SocketStream: ByteStream {
    private let fd: Int32

    init(fd: Int32) {
        self.fd = fd
    }

    func readExact(_ count: Int) throws -> Data {
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while data.count < count {
            let want = min(count - data.count, buffer.count)
            let received = read(fd, &buffer, want)
            if received <= 0 { throw TransportError.streamClosed }
            data.append(contentsOf: buffer[0..<received])
        }
        return data
    }

    func write(_ data: Data) throws {
        let bytes = [UInt8](data)
        var sent = 0
        while sent < bytes.count {
            let written = bytes.withUnsafeBytes { pointer in
                Foundation.write(fd, pointer.baseAddress!.advanced(by: sent), bytes.count - sent)
            }
            if written <= 0 { throw TransportError.streamClosed }
            sent += written
        }
    }

    func close() {
        _ = Foundation.close(fd)
    }
}

func connectWithRetry(host: String, port: UInt16, attempts: Int, delayMillis: UInt32) -> Int32? {
    for _ in 0..<attempts {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        if fd >= 0 {
            var address = sockaddr_in()
            address.sin_family = sa_family_t(AF_INET)
            address.sin_port = port.bigEndian
            inet_pton(AF_INET, host, &address.sin_addr)
            let result = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            if result == 0 { return fd }
            _ = Foundation.close(fd)
        }
        usleep(delayMillis * 1000)
    }
    return nil
}

func hex(_ data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
}

let arguments = CommandLine.arguments
let host = arguments.count > 1 ? arguments[1] : "127.0.0.1"
let port = arguments.count > 2 ? (UInt16(arguments[2]) ?? 38520) : 38520
let message = "hello from swift"

guard let fd = connectWithRetry(host: host, port: port, attempts: 50, delayMillis: 200) else {
    FileHandle.standardError.write(Data("could not connect to \(host):\(port)\n".utf8))
    exit(1)
}

let stream = SocketStream(fd: fd)
do {
    let identity = DeviceIdentity.generate()
    let channel = try SecureChannel.handshake(role: .initiator, identity: identity, stream: stream)
    try channel.send(FrameCodec.encode(.control(payload: Data(message.utf8))))
    let response = try FrameCodec.decode(channel.receive())
    guard case let .control(payload) = response else {
        FileHandle.standardError.write(Data("expected control frame\n".utf8))
        exit(2)
    }
    let ack = String(decoding: payload, as: UTF8.self)
    print("SAS=\(channel.sas)")
    print("REMOTE=\(hex(channel.remoteStaticPublicKey))")
    print("ACK=\(ack)")
    stream.close()
    exit(ack == "ack:\(message)" ? 0 : 3)
} catch {
    FileHandle.standardError.write(Data("interop error: \(error)\n".utf8))
    exit(4)
}
