// Source: https://weechat.org/files/doc/devel/weechat_relay_protocol.en.html#command_init
//
//  InitCommand.swift
//  
//
//  Created by Michael Eisemann on 5/29/23.
//

public struct InitCommand: WeeChatCommand {
    public let command: Command = .`init`
    public var arguments: String
    
}
