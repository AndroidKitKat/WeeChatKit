// Commands are messages that sent from the client -> relay
//
// Commands have the format:
// (id) command arguments\n

protocol WeechatCommand {
    var id: String { get }
    var command: Command { get }
    var arguments: String { get }    
}

func buildArgumentString<T: WeechatCommandArgument>(for enums: [T]) -> String where T.RawValue: CustomStringConvertible {
    let description: String = enums.description
    var values: [String] = []
    
    for value: T in enums {
        let val: String = String(describing: value.rawValue)
        values.append(val)
    }
    return "\(description)=\(values.joined(separator: ":"))"
}

protocol WeechatCommandArgument: RawRepresentable, CustomStringConvertible {}

enum Command: String, CaseIterable {
    case handshake      // Prepare client auth and set options, before init
    case `init`         // Authenticate with relay
    case hdata          // Request a hdata
    case info           // request an info
    case infolist       // request an infolist
    case nicklist       // request a nicklist
    case input          // Send data to a buffer (text or command)
    case completition   // Request completition for a string
    case sync           // Syncronize a buffer(s), get updates 
    case desync         // Stop syncronizing a buffer(s)
    case quit           // Disconnect from relay
}

// MARK: - Handshake

