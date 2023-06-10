//
//  WeeChatCommand.swift
//
//
//  Created by Michael Eisemann on 6/8/23.
//

/*
 
 Commands have the format:
 
 (id) command arguments\n
 
 Fields are:
   - id: optional message identifier that will be sent in answer from relay
   - command: a command
   - arguments: optional arguments for command (many args are separated by spaces)
 
 */

import Foundation

//struct WeeChatCommand: CustomStringConvertible {
//    let id: String = "wck"
//    let command: Command
//    let arguments: [String]
//    
//    var description: String {
//        return "(\(id)) \(command) \(arguments.joined(separator: " "))"
//    }
//}

protocol WeeChatCommand {
    var command: Command { get }
    var arguments: String { get } // I will have to determine commas or spaces myself
}

extension WeeChatCommand {
    var id: String {
        return "wck"
    }
    
    var rawValue: String {
        return "(\(id)) \(command.description) \(arguments)\n"
    }
    
}

enum Command: CustomStringConvertible {
    case handshake, initialize, hdata, info, infolist, nicklist, input, completion, sync, desync, quit
    
    var description: String {
        switch self {
        case .handshake:
            "handshake"
        case .initialize:
            "init"
        case .hdata:
            "hdata"
        case .info:
            "info"
        case .infolist:
            "infolist"
        case .nicklist:
            "nicklist"
        case .input:
            "input"
        case .completion:
            "completion"
        case .sync:
            "sync"
        case .desync:
            "desync"
        case .quit:
            "quit"
        }
    }
}




extension Array where Element: CustomStringConvertible {
    func joinedDescription(separator: String) -> String {
        return map { $0.description }.joined(separator: separator)
    }
}
