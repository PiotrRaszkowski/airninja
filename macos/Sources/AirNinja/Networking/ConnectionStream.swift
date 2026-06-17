import AirNinjaCore
import Foundation
import Network

/// Blocking `ByteStream` over an `NWConnection`, so the synchronous `SecureChannel`
/// handshake/transport can run on a worker thread while Network.framework drives I/O.
final class ConnectionStream: ByteStream {
    private let connection: NWConnection
    private let condition = NSCondition()
    private var buffer = Data()
    private var closed = false
    private var failure: Error?

    init(connection: NWConnection) {
        self.connection = connection
        pump()
    }

    private func pump() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            self.condition.lock()
            if let data, !data.isEmpty {
                self.buffer.append(data)
            }
            if let error {
                self.failure = error
            }
            if isComplete || error != nil {
                self.closed = true
            }
            self.condition.broadcast()
            self.condition.unlock()
            if !isComplete && error == nil {
                self.pump()
            }
        }
    }

    func readExact(_ count: Int) throws -> Data {
        condition.lock()
        defer { condition.unlock() }
        while buffer.count < count {
            if let failure {
                throw failure
            }
            if closed {
                throw TransportError.streamClosed
            }
            condition.wait()
        }
        let result = Data(buffer.prefix(count))
        buffer.removeFirst(count)
        return result
    }

    func write(_ data: Data) throws {
        let semaphore = DispatchSemaphore(value: 0)
        var sendError: Error?
        connection.send(content: data, completion: .contentProcessed { error in
            sendError = error
            semaphore.signal()
        })
        semaphore.wait()
        if let sendError {
            throw sendError
        }
    }
}
