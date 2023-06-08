import NIO
import NIOConcurrencyHelpers

public final class WeeChatKit {
    private let eventLoopGroup: EventLoopGroup
    private var channel: Channel?

    public init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
    }

    public func connect(host: String, port: Int) async throws {
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
        guard let rawBytes = receivedData.readBytes(length: receivedData.readableBytes) else {
            return
        }
        
        print(rawBytes)
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
