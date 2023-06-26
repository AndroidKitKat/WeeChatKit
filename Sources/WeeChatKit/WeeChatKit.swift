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
        print("Incoming bytes of size \(bytes.count)")
        print(String(decoding: bytes, as: UTF8.self))
        // MARK: Message header
        let messageLength: Int32 = bytes.consume(first: 4).reduce(0) { soFar, byte in
            return soFar << 8 | Int32(byte)
        }
        print("Message length: \(messageLength)")
                
        var messageData: Data
        let compressionFlag = bytes.consume().reduce(0) { soFar, byte in
            return soFar << 8 | Int8(byte)
        }
        switch compressionFlag {
        case 0:
            print("Compression: None!")
            messageData = bytes
        default:
            print("Compressed data encountered!")
            print("Only bad things can happen here!")
            exit(EXIT_FAILURE)
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
        
        print("Message id: \(messageId)")
        
        // MARK: Message consuming
        
        while (!messageData.isEmpty) {
            let objTypeString: String = String(decoding: messageData.consume(first: 3), as: UTF8.self)
            print("Object type is: \(objTypeString) <- there should be something here")
            let objType = WCKObjectType(rawValue: objTypeString)

            switch objType {
            case .chr:
                print("Char parsing")
                print(WCKChar(data: &messageData).charValue)
            case .int:
                print("int parsing")
                print(WCKInteger(data: &messageData).value)
            case .lon:
                print("long parsing")
                print(WCKLongInteger(data: &messageData).value)
            case .str:
                print("string parsing")
                print(WCKString(data: &messageData).value!)
            case .buf:
                print("buffer parsing")
                print(WCKBuffer(data: &messageData).value!)
            case .ptr:
                print("pointer parsing")
                print(WCKPointer(data: &messageData).value)
            case .tim:
                print("time parsing")
                print(WCKTime(data: &messageData).value)
            case .htb:
                print("hashtable parsing")
                print(WCKHashtable(data: &messageData).value as AnyObject)
            case .hda:
                print("hda parsing")
                exit(EXIT_FAILURE)
            case .inf:
                print("inf parsing")
                exit(EXIT_FAILURE)
            case .inl:
                print("inl parsing")
                exit(EXIT_FAILURE)
            case .arr:
                print("array parsing")
                exit(EXIT_FAILURE)
            case .none:
                print("something bad happened?")
                
            }
        }
        
        
        // now based on that, let's get it
        // that is the effective loop for parsing, now we just have to actually it
        
        
        print(String(decoding: messageData, as: UTF8.self))
        print("Done with that message")
        
         
        
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
