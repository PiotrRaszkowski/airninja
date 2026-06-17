import Foundation

public enum Frame: Equatable {
    case control(payload: Data)
    case data(streamId: UInt32, sequence: UInt64, isFinal: Bool, chunk: Data)
}
