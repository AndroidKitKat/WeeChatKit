import NIO
import NIOWebSocket
import Foundation

public class SimpleDispatcher {
    private let group: MultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var channel: Channel?

    public static let `default` = SimpleDispatcher()

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
        channel = try bootstrap.connect(host: "localhost", port: 9001).wait()
    }

    public func waitForHangup() throws {
        try channel?.closeFuture.wait()
    }
    
    public func stop() throws {
        try group.syncShutdownGracefully()
    }
}

class SimpleHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer: SimpleHandler.InboundIn = self.unwrapInboundIn(data)
        if let response = buffer.readString(length: buffer.readableBytes) {
            print(response.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        print("well that's all folks")
        context.close(promise: nil)
    }
}

// // public final class NetworkHandler: ChannelInboundHandler {

//     // public static let `default`: NetworkHandler = NetworkHandler()
//     private var group: MultiThreadedEventLoopGroup?
//     private var channel: Channel?
//     // private var buffer: ByteBuffer = ByteBufferAllocator().buffer(capacity: 0)

//     public typealias InboundIn = ByteBuffer
//     public typealias InboundOut = ByteBuffer


//     public func connect() throws {
//         group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//         let bootstrap: ClientBootstrap = ClientBootstrap(group: group!)
//             .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
//             .channelInitializer { channel in 
//                 channel.pipeline.addHandler(Dispatcher())
//         }

//         channel = try bootstrap.connect(host: "localhost", port: 9001).wait()
//     }

//     public func disconnect() throws {
//         print("Disconnecting...")
//         try channel?.close().wait()
//         try group?.syncShutdownGracefully()
//     }

//     public func channelActive(context: ChannelHandlerContext) {
//         print("connected to \(context.remoteAddress!)")
//         self.channel = context.channel
//     }

//     public func channelInactive(context: ChannelHandlerContext) throws {
//         print("disconnected from \(context.remoteAddress!)")
//         try disconnect()
//         self.channel = nil
//     }

//     private class Dispatcher: ChannelInboundHandler {
//         typealias InboundIn = ByteBuffer

//         func channelRead(context: ChannelHandlerContext, data: NIOAny) {
//             let buffer: NetworkHandler.Dispatcher.InboundIn = unwrapInboundIn(data)

//             if let message: String = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes)
//             {
//                 print(message.trimmingCharacters(in: .newlines))
//             }
//         }

//         // close the connection if the other side hangs up
//         func channelInactive(context: ChannelHandlerContext) {
//             context.close(promise: nil)
//             print("you are done!")
//         }
//     }
// }