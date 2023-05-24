import NIO
import NIOWebSocket
import Foundation
import zstd

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
        
        print("Correct size: \(String(buffer.readableBytes, radix:10))")
        
        guard let rawBytes = buffer.readBytes(length: buffer.readableBytes) else {
            return
        }
        
        var bytes = Data(rawBytes)
        
        let size = bytes.consume(first: 4).reduce(0) { soFar, byte in
            return soFar << 8 | UInt32(byte)
        }
        print(size)
        
        let compressionFlag = bytes.consume()
        print(compressionFlag)
        
//        if var bytes = Data(rawBytes) {
//
//            // print("My Length: \(buffer.readableBytes)")
//            let size = bytes.consumeFirst(4).reduce(0) { soFar, byte in
//                return soFar << 8 | UInt32(byte)
//            }
//
//            let compressionFlag = bytes.consumeFirst(1).reduce(0) { soFar, byte in
//                return soFar << 8 | UInt8(byte)
//            }
//
//
//            let rawBytes = Data(bytes)
//            var messageData: Data
//
//            switch compressionFlag {
//            case 0:
//                // do nothing
//                print("Data is not compressed")
//                messageData = rawBytes
//                break
//            case 1:
//                print("Data is compressed with zlib")
//                do {
//                    messageData = try (rawBytes as NSData).decompressed(using: .zlib) as Data
//                } catch {
//                    print(error.localizedDescription)
//                }
//                break
//            case 2:
//                print("Data is compressed with Zstd")
//                do {
//                    messageData = try ZStd.decompress(rawBytes)
//                } catch {
//                    print(error.localizedDescription)
//                }
//                break
//            default:
//                messageData = rawBytes
//            }
//
//            let idSize = messageData.
//
            
            
//            let idSize = bytes.consumeFirst(4).reduce(0) { soFar, byte in
//                return soFar << 8 | UInt32(byte)
//            }
//
//            guard let messageId = String(bytes: bytes.consumeFirst(idSize), encoding: .utf8) else {
//                return
//            }
//
//            print(String(size, radix: 10))
//            print(String(idSize, radix: 10))
//        }
        
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
    
    mutating func consumeFirst(_ count: UInt32) -> ArraySlice<Element> {
        return consumeFirst(Int(count))
    }
}

extension Data {
    mutating func consume(first count: Int ) -> Data {
        let prefixData = self.prefix(count)
        self.removeFirst(count)
        return Data(prefixData)
    }
    
    mutating func consume(last count: Int) -> Data {
        let suffixData = self.suffix(count)
        self.removeLast(count)
        return Data(suffixData)
    }
    
    mutating func consume() -> Data {
        return consume(first: 1)
    }
}
