//  Source: https://weechat.org/files/doc/devel/weechat_relay_protocol.en.html#command_hdata
//
//  HdataCommand.swift
//  
//
//  Created by Michael Eisemann on 5/29/23.
//

public enum HdataPathType: String, CaseIterable, CustomStringConvertible {
    case hdata
    case pointer
    case `var`
    
    public var description: String {
        return self.rawValue
    }
}


public struct HdataPath {
    let type: HdataPathType
    let value: String
    
}
public struct HdataCommand: WeeChatCommand {
    public let command: Command = .hdata
    
    public let arguments: String
    

}
