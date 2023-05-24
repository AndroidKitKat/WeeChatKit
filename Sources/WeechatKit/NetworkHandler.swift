import NIO
import NIOWebSocket
import Foundation

public class NetworkHandler {
    private let group: MultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var channel: Channel?

    public static let `default`: NetworkHandler = NetworkHandler()
    
    public var connected: Bool = false
    private var timeout: Double = 3.0

    public init() {}
    
    public func start() throws {
        let bootstrap: ClientBootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                let handler: SimpleHandler = SimpleHandler()
                let pipeline: ChannelPipeline = channel.pipeline
                _ = pipeline.addHandler(handler)
                return channel.eventLoop.makeSucceededFuture(())
            }
        channel = try bootstrap.connect(host: "localhost", port: 9000).wait()
        connected = true
    }
    
    public func stop() throws {
        try group.syncShutdownGracefully()
    }

    public func waitForHangup() throws {
        try channel?.closeFuture.wait()
    }

    // Send function that sends a string message to the server
    // if the write succeeds, return true, else return false
    public func send(_ message: String) -> Bool {
        // this ensures that the channel is at least a thing
        guard let channel = channel else {
            return false
        }
        var buffer: ByteBuffer = channel.allocator.buffer(capacity: message.utf8.count)
        buffer.writeString(message)
        do {
            try channel.writeAndFlush(buffer).wait()
            return true
        } catch {
            return false
        }
    }

    public func send(command: WeeChatCommand) -> Bool {
        let message: String = "(\(command.id)) \(command.command.rawValue) \(command.arguments)\n"
        return send(message)
    }

    public func sendWeeChatHandshake(_ handshake: HandshakeCommand) -> Bool {
        return send(command: handshake) 
    }
    
}

class SimpleHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer: SimpleHandler.InboundIn = self.unwrapInboundIn(data)

        if var bytes = buffer.readBytes(length: buffer.readableBytes) {
            // print("My Length: \(buffer.readableBytes)")
            let size = bytes.consumeFirst(4).reduce(0) { soFar, byte in
                return soFar << 8 | UInt32(byte)
            }
            
            let compression = bytes.consumeFirst(1).reduce(0) { soFar, byte in
                return soFar << 8 | UInt32(byte)
            }
//
//            let compression = bytes.dropFirst(1).reduce(0) { soFar, byte in
//                return soFar << 8 | UInt32(byte)
//            }

            print(String(size, radix: 10))
            print(String(compression, radix: 16))
        }

        // if let response: String = buffer.readString(length: buffer.readableBytes) {
        //     print(response.trimmingCharacters(in: .whitespacesAndNewlines))
        // }
    }

    // send a message to the server when the connection is established

    
    func channelInactive(context: ChannelHandlerContext) {
        print("well that's all folks")
        context.close(promise: nil)
    }
}

extension Array {
    mutating func consumeFirst(_ count: Int) -> ArraySlice<Element> {
        let range = 0..<Swift.min(count, self.count)
        let slice = self[range]
        self.removeFirst(range.count)
        return slice
    }
}

