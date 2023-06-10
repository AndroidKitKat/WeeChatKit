import NIO
import NIOConcurrencyHelpers
import Foundation

public final class WeeChatKit {
    private let eventLoopGroup: EventLoopGroup
    private var channel: Channel?

    public init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
    }

    public func connect(to host: String, on port: Int) async throws {
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(SocketHandler())
            }

        channel = try await bootstrap.connect(host: host, port: port).get()
        
    }

    public func disconnect() async throws {
        guard let existingChannel = channel else {
            return
        }

        try await existingChannel.close().get()
        channel = nil
    }

    public func sendData(_ data: ByteBuffer) async throws {
        guard let existingChannel = channel else {
            throw SocketError.notConnected
        }

        try await existingChannel.writeAndFlush(data).get()
    }

    public func receiveData() async throws -> ByteBuffer {
        guard let existingChannel = channel else {
            throw SocketError.notConnected
        }

        let promise = existingChannel.eventLoop.makePromise(of: ByteBuffer.self)
        try await existingChannel.pipeline.addHandler(ReadDataHandler(promise: promise))

        return try await promise.futureResult.get()
    }
}

enum SocketError: Error {
    case notConnected
}

class SocketHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var receivedData = unwrapInboundIn(data)
        guard let rawBytes: [UInt8] = receivedData.readBytes(length: receivedData.readableBytes) else {
            return
        }
        
        var bytes: Data = Data(rawBytes)
        // MARK: Message header
        let messageLength: UInt32 = bytes.consume(first: 4).reduce(0) { soFar, byte in
            return soFar << 8 | UInt32(byte)
        }
        print(messageLength)
        
        var messageData: Data
        switch bytes.consume()[0] {
        case 0:
            print("none")
            messageData = bytes
        default:
            print("Compressed data encountered!")
            return
//        case 1:
//            print("zlib")
//            break
//        case 2:
//            print("zstd")
//            break
//        default:
//            print("idk")
        }
        
        // MARK: Message ID handling
        
        let idLength: UInt32 = messageData.consume(first: 4).reduce(0){ soFar, byte in
            return soFar << 8 | UInt32(byte)
        }
        
        let messageId: String = String(decoding: messageData.consume(first: Int(idLength)), as: UTF8.self)
        
        // MARK: Message delegate
        
         
        
    }
}

class ReadDataHandler: ChannelInboundHandler, RemovableChannelHandler {
    func removeHandler(context: NIOCore.ChannelHandlerContext, removalToken: NIOCore.ChannelHandlerContext.RemovalToken) {
        
    }
    
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer

    private let promise: EventLoopPromise<ByteBuffer>

    init(promise: EventLoopPromise<ByteBuffer>) {
        self.promise = promise
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let receivedData = unwrapInboundIn(data)
        promise.succeed(receivedData)
        _ = context.pipeline.removeHandler(self)
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
