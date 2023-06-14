//
//  Objects.swift
//
//
//  Created by Michael Eisemann on 6/10/23.
//

import Foundation

enum ObjectType: String {
    case chr, int, lon, str, buf, ptr, tim, htb, hda, inf, inl, arr
}

struct WCKChar: Hashable {
    let value: UInt8
    let type: ObjectType = .chr
    
    init(value: UInt8) {
        self.value = value
    }
    
    init (data: inout Data) {
        self.value = data.consume().reduce(0) { soFar, byte in
            return soFar << 8 | UInt8(byte)
        }
    }
}

struct WCKInteger: Hashable {
    let value: Int32
    let type: ObjectType = .int
    
    init(value: Int32) {
        self.value = value
    }
    
    init(data: inout Data) {
        self.value = data.consume(first: 4).reduce(0) { soFar, byte in
            return soFar << 8 | Int32(byte)
        }
    }
}

struct WCKLongInteger: Hashable {
    let value: Int64
    let type: ObjectType = .lon
    
    init(value: Int64) {
        self.value = value
    }
    
    init(data: inout Data) {
        let longLength = data.consume().reduce(0) { soFar, byte in
            return soFar << 8 | Int8(byte)
        }
        self.value = Int64(String(decoding: data.consume(first: Int(longLength)), as: UTF8.self))!
    }
}

struct WCKString: Hashable {
    let value: String?
    let type: ObjectType = .str
    
    init(value: String?) {
        self.value = value
    }
    
    init(data: inout Data) {
        let stringLength = data.consume(first: 4).reduce(0) { soFar, byte in
            return soFar << 8 | Int32(byte)
        }
        
        switch stringLength {
        case 0:
            self.value = ""
        case -1:
            self.value = nil
        default:
            self.value = String(decoding: data.consume(first: Int(stringLength)), as: UTF8.self)
        }
    }
}

struct WCKBuffer: Hashable {
    let value: [UInt8]?
    let type: ObjectType = .buf
    
    init(value: [UInt8]?) {
        self.value = value
    }
    
    init(data: inout Data) {
        let bufferLength = data.consume(first: 4).reduce(0) { soFar, byte in
            return soFar << 8 | Int32(byte)
        }
        
        switch bufferLength {
        case 0:
            self.value = []
        case -1:
            self.value = nil
        default:
            let bufferData = data.consume(first: Int(bufferLength))
            self.value = [UInt8](bufferData)
        }
    }
    
}

struct WCKPointer: Hashable {
    let value: String
    let type: ObjectType = .ptr
    
    init(value: String) {
        self.value = value
    }
    
    init(data: inout Data) {
        let pointerLength = data.consume().reduce(0) { soFar, byte in
            return soFar << 8 | Int8(byte)
        }
        let pointerAddress = String(decoding: data.consume(first: Int(pointerLength)), as: UTF8.self)
        
        self.value = "0x" + pointerAddress
    }
}

struct WCKTime: Hashable {
    let value: Int
    let type: ObjectType = .tim
    init(value: Int) {
        self.value = value
    }
    
    init(data: inout Data) {
        let timeLength = data.consume().reduce(0) { soFar, byte in
            return soFar << 8 | Int8(byte)
        }
        
        self.value = Int(String(decoding: data.consume(first: Int(timeLength)), as: UTF8.self))!
    }
}

struct WCKHashtable: Hashable {
    static func == (lhs: WCKHashtable, rhs: WCKHashtable) -> Bool {
        lhs.itemsCount == rhs.itemsCount
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemsCount)
        hasher.combine(keysType.rawValue)
        hasher.combine(valuesType.rawValue)
    }
    
    let keysType: ObjectType
    let valuesType: ObjectType
    let itemsCount: WCKInteger
    let value: [AnyHashable: Any]
    let type: ObjectType = .htb
    
    init(keysType: ObjectType, valuesType: ObjectType, itemsCount: WCKInteger, value: [AnyHashable : Any]) {
        self.keysType = keysType
        self.valuesType = valuesType
        self.itemsCount = itemsCount
        self.value = value
    }
    
    init(data: inout Data) {
        // read the first type
        self.keysType = ObjectType(rawValue: String(decoding: data.consume(first: 3), as: UTF8.self))!
        
        self.valuesType = ObjectType(rawValue: String(decoding: data.consume(first: 3), as: UTF8.self))!
        
        self.itemsCount = WCKInteger(data: &data)
        
        var newItems: [AnyHashable: Any] = [:]
        for _ in 0..<self.itemsCount.value {
        }
        
        self.value = newItems
    }
    
    func munch(data: inout Data, for type: ObjectType) -> Any {
        var byproduct: Any
        switch type {
        case .chr:
            byproduct = WCKChar(data: &data)
        case .int:
            byproduct = WCKInteger(data: &data)
        case .lon:
            byproduct = WCKLongInteger(data: &data)
        case .str:
            byproduct = WCKString(data: &data)
        case .buf:
            byproduct = WCKBuffer(data: &data)
        case .ptr:
            byproduct = WCKPointer(data: &data)
        case .tim:
            byproduct = WCKTime(data: &data)
        case .htb:
            byproduct = WCKHashtable(data: &data)
        case .hda:
            byproduct = WCKHdata()
        case .inf:
            byproduct = WCKInfo()
        case .inl:
            byproduct = WCKInfoList()
        case .arr:
            byproduct = WCKArray()

        }
        return 0
    }
    
}

struct WCKHdata: Hashable {}

struct WCKInfo: Hashable {}

struct WCKInfoList: Hashable {}

struct WCKArray: Hashable {}
