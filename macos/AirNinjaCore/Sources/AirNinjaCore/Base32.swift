import Foundation

public enum Base32 {
    private static let alphabet = Array("abcdefghijklmnopqrstuvwxyz234567")
    private static let bitsPerSymbol = 5
    private static let byteBits = 8
    private static let symbolMask = 0x1F

    public static func encodeLowerNoPadding(_ data: Data) -> String {
        var result = ""
        var buffer = 0
        var bitsLeft = 0
        for byte in data {
            buffer = (buffer << byteBits) | Int(byte)
            bitsLeft += byteBits
            while bitsLeft >= bitsPerSymbol {
                let index = (buffer >> (bitsLeft - bitsPerSymbol)) & symbolMask
                result.append(alphabet[index])
                bitsLeft -= bitsPerSymbol
            }
        }
        if bitsLeft > 0 {
            let index = (buffer << (bitsPerSymbol - bitsLeft)) & symbolMask
            result.append(alphabet[index])
        }
        return result
    }
}
