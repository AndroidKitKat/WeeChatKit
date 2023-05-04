// Source: https://weechat.org/files/doc/stable/weechat_relay_protocol.en.html#command_handshake

enum HandshakeOptions: String, CaseIterable {
    case password_hash_algo
    case compression
}

enum PasswordHashAlgos: String, CaseIterable, CustomStringConvertible {
    case plain
    case sha256
    case sha512
    case pbkdf2_sha256 = "pbkdf2+sha256"
    case pbkdf2_sha512 = "pbkdf2+sha512"

    var description: String {
        return "password_hash_algo"
    }
}

enum CompressionAlgos: String, CaseIterable, CustomStringConvertible {
    case off
    case zlib
    case zstd
    var description: String {
        return "compression"
    }
}

struct HandshakeCommand: WeechatCommand {
    let id: String
    let command: Command = .handshake
    let arguments: String
    
    init(id: String, passwordHashAlgo: [PasswordHashAlgos], compressionAlgo: [CompressionAlgos]) {
        self.id = id
        // arguments should be [<option>=<value>,<option>=<value>,...]


    }
}