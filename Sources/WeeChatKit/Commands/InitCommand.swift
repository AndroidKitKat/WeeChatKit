//
//  InitCommand.swift
//
//
//  Created by Michael Eisemann on 6/10/23.
//

struct InitCommand: WeeChatCommand {
    var arguments: String
    let command: Command = .initialize
    
//    init(
}

struct InitPassword {
    let authMethod: InitAuthenticationMethod
    let totpSecret: String?
    let hashAlgos: [HandshakeHashAlgos]
    let salt: String?
    let iterations: Int?
}

enum InitAuthenticationMethod {
    case password, pasword_hash
}
