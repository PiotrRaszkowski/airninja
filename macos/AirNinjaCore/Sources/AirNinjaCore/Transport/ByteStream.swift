import Foundation

public protocol ByteStream {
    func readExact(_ count: Int) throws -> Data
    func write(_ data: Data) throws
}

public enum TransportError: Error, Equatable {
    case frameTooLarge
    case streamClosed
}
