import Foundation

struct PendingPairing: Identifiable {
    let id = UUID()
    let sas: String
    let deviceId: String
    let onAccept: () -> Void
    let onReject: () -> Void
}
