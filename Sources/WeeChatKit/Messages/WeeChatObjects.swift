//
//  WeeChatObjects.swift
//
//
//  Created by Michael Eisemann on 6/10/23.
//

import Foundation

enum WCKObjectType: String {
    case chr, int, lon, str, buf, ptr, tim, htb, hda, inf, inl, arr
    
    var type: Any.Type? {
        switch self {
        case .chr:
            return WCKChar.self
        case .int:
            return WCKInteger.self
        case .lon:
            return WCKLongInteger.self
        case .str:
            return WCKString.self
        case .buf:
            return WCKBuffer.self
        case .ptr:
            return WCKPointer.self
        case .tim:
            return WCKTime.self
        case .htb:
            return WCKHashtable.self
        case .hda:
            return WCKHdata.self
        case .inf:
            return WCKInfo.self
        case .inl:
            return WCKInfoList.self
        case .arr:
            return WCKArray.self
        }
    }
    
}

struct WCKChar: Hashable {
    let value: UInt8
    let type: WCKObjectType = .chr
    let charValue: Character
    
    init(value: UInt8) {
        self.value = value
        self.charValue = Character(UnicodeScalar(value))
    }
    
    init (data: inout Data) {
        let newValue = data.consume().reduce(0) { soFar, byte in
            return soFar << 8 | UInt8(byte)
        }
        
        self.value = newValue
        self.charValue = Character(UnicodeScalar(newValue))
    }
}

struct WCKInteger: Hashable {
    let value: Int32
    let type: WCKObjectType = .int
    
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
    let type: WCKObjectType = .lon
    
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
    let type: WCKObjectType = .str
    
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
    let type: WCKObjectType = .buf
    
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
    let type: WCKObjectType = .ptr
    
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
    let type: WCKObjectType = .tim
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
    //TODO: This is not good
    static func == (lhs: WCKHashtable, rhs: WCKHashtable) -> Bool {
        lhs.itemsCount == rhs.itemsCount
    }
    
    //TODO: Same with this 
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemsCount)
        hasher.combine(keysType.rawValue)
        hasher.combine(valuesType.rawValue)
    }
    
    let keysType: WCKObjectType
    let valuesType: WCKObjectType
    let itemsCount: WCKInteger
    let value: [AnyHashable: Any]
    let type: WCKObjectType = .htb
    
    init(keysType: WCKObjectType, valuesType: WCKObjectType, itemsCount: WCKInteger, value: [AnyHashable : Any]) {
        self.keysType = keysType
        self.valuesType = valuesType
        self.itemsCount = itemsCount
        self.value = value
    }
    
    init(data: inout Data) {
        // read the first type
        let keysType = WCKObjectType(rawValue: String(decoding: data.consume(first: 3), as: UTF8.self))!
        self.keysType = keysType
    
        let valuesType = WCKObjectType(rawValue: String(decoding: data.consume(first: 3), as: UTF8.self))!
        self.valuesType = valuesType
        
        self.itemsCount = WCKInteger(data: &data)

        var newItems: [AnyHashable: Any] = [:]
        
        for _ in 0..<self.itemsCount.value {
            let newKey = munch(data: &data, for: keysType) as! (any Hashable) // i need to turn Any into keysType
            let newValue = munch(data: &data, for: valuesType)
            
            newItems[AnyHashable(newKey)] = newValue
        }
        
        self.value = newItems
    }
}

struct WCKHdata: Hashable {}

struct WCKInfo: Hashable {}

struct WCKInfoList: Hashable {}

struct WCKArray: Hashable {
    static func == (lhs: WCKArray, rhs: WCKArray) -> Bool {
        lhs.itemsCount == rhs.itemsCount
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemsCount)
        hasher.combine(itemsType)
    }
    
    let itemsType: WCKObjectType
    let itemsCount: WCKInteger
    let items: [Any]
    
    init(data: inout Data) {
        let memberType = WCKObjectType(rawValue: String(decoding: data.consume(first: 3), as: UTF8.self))!
        self.itemsType = memberType
         
        let memberCount = WCKInteger(data: &data)
        self.itemsCount = memberCount
        
        var newItems: [Any] = []
        for _ in 0..<memberCount.value {
            let newItem = munch(data: &data, for: itemsType)
            newItems.append(newItem)
        }
        self.items = newItems
    }
    
}


func munch(data: inout Data, for type: WCKObjectType) -> Any {
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
        byproduct = 0
    case .inf:
        byproduct = 0
    case .inl:
        byproduct = 0
    case .arr:
        byproduct = 0

    }
    return byproduct
}
