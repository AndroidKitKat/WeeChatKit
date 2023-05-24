// Source: https://weechat.org/files/doc/stable/weechat_relay_protocol.en.html#command_handshake

// enum HandshakeOptions: String, CaseIterable {
//     case password_hash_algo
//     case compression
// }

public enum PasswordHashAlgos: String, CaseIterable, CustomStringConvertible {
    case plain
    case sha256
    case sha512
    case pbkdf2_sha256 = "pbkdf2+sha256"
    case pbkdf2_sha512 = "pbkdf2+sha512"

    public var description: String {
        return "password_hash_algo"
    }
}

extension PasswordHashAlgos: WeeChatCommandArgument {}

public enum CompressionAlgos: String, CaseIterable, CustomStringConvertible {
    case off
    case zlib
    case zstd
    public var description: String {
        return "compression"
    }
}

extension CompressionAlgos: WeeChatCommandArgument {}

public struct HandshakeCommand: WeeChatCommand {
    public let id: String
    public let command: Command = .handshake
    public let arguments: String
    
    public init(id: String = String(Int.random(in: 0..<1_000_000_00)) , passwordHashAlgos: [PasswordHashAlgos], compressionAlgos: [CompressionAlgos]) {
        self.id = id
        // join build argument string with a comma
        self.arguments = buildArgumentString(for:passwordHashAlgos) + "," + buildArgumentString(for:compressionAlgos)
    }
}
// MARK
