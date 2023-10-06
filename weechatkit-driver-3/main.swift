//
//  main.swift
//  weechatkit-driver-3
//
//  Created by Michael Eisemann on 6/8/23.
//

import Foundation
import WeeChatKit

import NIO
import NIOConcurrencyHelpers

func main() async throws {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let communicator = WeeChatKit(eventLoopGroup: eventLoopGroup)

    // Connect to the server
    try await communicator.connect(to: "localhost", on: 9001)
    print("Connected to server. You can start sending messages.")

    // Start receiving messages in the background
    Task.detached {
        do {
            while true {
                let receivedData = try await communicator.receiveData()
                let receivedMessage = String(decoding: receivedData.readableBytesView, as: UTF8.self)
                print("Received message: \(receivedMessage)")
            }
        } catch {
            print("Error receiving data: \(error)")
            exit(5)
        }
    }

    // Send messages until user decides to quit
    print(">>> ", terminator: "")
    while let userInput = readLine(strippingNewline: true) {
        if userInput.lowercased() == "quit" {
            break
        }
        
        
        let message = "(wck) " + userInput + "\n"
        let messageData = ByteBuffer(bytes: Array(message.utf8))
        do {
            try await communicator.sendData(messageData)
            print("Message sent.")
        } catch {
            print("Error sending data: \(error)")
            exit(5)
        }
        print(">>> ", terminator: "")
    }

    // Disconnect from the server
    try await communicator.disconnect()
    print("Disconnected from server.")

    // Shutdown the event loop group
    try await eventLoopGroup.shutdownGracefully()
}

do {
    try await main()
} catch {
    print("Error: \(error)")
    exit(69)
}


