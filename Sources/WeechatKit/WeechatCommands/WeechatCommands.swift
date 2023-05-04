// Commands are messages that sent from the client -> relay
//
// Commands have the format:
// (id) command arguments\n

protocol WeechatCommand {
    var id: String { get }
    var command: Command { get }
    var arguments: String { get }    
}

extension WeechatCommand {
    // func buildArguments() TODO
}


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

