//
//  HandshakeCommand.swift
//
//
//  Created by Michael Eisemann on 6/8/23.
//


struct HandshakeCommand: WeeChatCommand {
    var arguments: String
    let command: Command = .handshake
    
    init(hashAlgos: [HandshakeHashAlgos], compressionModes: [HandshakeCompressionModes]) {
        let argumentComponents = [
            hashAlgos.isEmpty ? nil : "password_hash_algo=" + hashAlgos.joinedDescription(separator: ":"),
            compressionModes.isEmpty ? nil : "compression=" + compressionModes.joinedDescription(separator: ":")
        ].compactMap { $0 }
        
        arguments = argumentComponents.joined(separator: ",")
    }
}

enum HandshakeHashAlgos: CustomStringConvertible {
    case plain, sha256, sha512, pdkdf2_sha256, pdkdf2_sha512
    var description: String {
        switch self {
        case .plain:
            return "plain"
        case .sha256:
            return "sha256"
        case .sha512:
            return "sha512"
        case .pdkdf2_sha256:
            return "pdkdf2+sha256"
        case .pdkdf2_sha512:
            return "pdkdf2+sha512"
        }
    }
}

enum HandshakeCompressionModes: CustomStringConvertible {
    case off, zlib, zstd
    
    var description: String {
        switch self {
        case .off:
            "off"
        case .zlib:
            "zlib"
        case .zstd:
            "zstd"
        }
    }
}

