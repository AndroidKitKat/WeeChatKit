//
//  Objects.swift
//
//
//  Created by Michael Eisemann on 6/10/23.
//

import Foundation


protocol WCKObject {
    var type: WCKVariableType { get }
}
//
//extension WCKObject {
//    var id: UUID {
//        UUID()
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//        hasher.combine(type.rawValue)
//    }
//}

enum WCKVariableType: String, CustomStringConvertible {
    case chr, int, lon, str, buf, ptr, tim, htb, hda, inf, inl, arr
    
    var description: String {
        switch self {
        case .chr:
            "chr"
        case .int:
            "int"
        case .lon:
            "lon"
        case .str:
            "str"
        case .buf:
            "buf"
        case .ptr:
            "ptr"
        case .tim:
            "tim"
        case .htb:
            "htb"
        case .hda:
            "hda"
        case .inf:
            "inf"
        case .inl:
            "inl"
        case .arr:
            "arr"
        }
    }
}

/// A simple one-byte char
struct WCKChar: WCKObject {
    let value: Int8
    let type: WCKVariableType = .chr
}

/// Signed 32-bit (4 byte) integers, encoded as big-endian (most significant byte first)
struct WCKInteger: WCKObject {
    let value: Int32
    let type: WCKVariableType = .int
    
    init(data: inout Data) {
        value = data.consume(first: 4).reduce(0) { soFar, byte in
            return soFar << 8 | Int32(byte)
        }
    }
    
    init(_ val: Int32) {
        value = val

    }
}


/// A signed long integer is encoded as a string, with length on one byte.
struct WCKLongInteger: WCKObject {
    let value: Int64
    let type: WCKVariableType = .lon
    
    init?(data: inout Data) {
        let longLength = data.consume().reduce(0) { soFar, byte in
            return soFar << 8 | UInt8(byte)
        }
        
        let longString = String(decoding: data.consume(first: Int(longLength)), as: UTF8.self)
        guard let longInt = Int64(longString) else { return nil }
        value = longInt
    }
    
    init(_ val: Int64) {
        value = val
    }
}

/// A string is a length (integer on 4 bytes) + content of string (without final \0).
struct WCKString: WCKObject {
    let value: String?
    let type: WCKVariableType = .str
    
    init(data: inout Data) {
        let stringLength = data.consume(first: 4).reduce(0) { soFar, byte in
            return soFar << 8 | Int32(byte)
        }
        
        switch stringLength {
        case 0:
            value = ""
        case -1:
            value = nil
        default:
            value = String(decoding: data.consume(first: Int(stringLength)), as: UTF8.self)
        }
    }
    
    init(_ val: String?) {
        value = val
    }
}

/// Same format as string; content is just an array of bytes.
struct WCKBuffer: WCKObject {
    let value: [UInt8]?
    let type: WCKVariableType = .buf
    
    init(data: inout Data) {
        let bufferLength = data.consume(first: 4).reduce(0) { soFar, byte in
            return soFar << 8 | Int32(byte)
        }
        
        switch bufferLength {
        case 0:
            value = []
        case -1:
            value = nil
        default:
            let bufferData = data.consume(first: Int(bufferLength))
            value = [UInt8](bufferData)
        }
    }
    
    init(_ val: [UInt8]?) {
        value = val
    }
}


/// A pointer is encoded as string (hex), with length on one byte.
struct WCKPointer: WCKObject {
    let value: String
    let type: WCKVariableType = .ptr
    
    init(data: inout Data) {
        let pointerLength = data.consume().reduce(0) { soFar, byte in
            return soFar << 8 | Int8(byte)
        }
        let pointerAddress = String(decoding: data.consume(first: Int(pointerLength)), as: UTF8.self)
        value = "0x" + pointerAddress
    }
    
    init(_ val: String) {
        value = val
    }
}


/// A time (number of seconds) is encoded as a string, with length on one byte.
struct WCKTime: WCKObject {
    let value: String
    let type: WCKVariableType = .tim
    
    init(data: inout Data) {
        let timeLength = data.consume().reduce(0) { soFar, byte in
            return soFar << 8 | Int8(byte)
        }
        let timeValue = String(decoding: data.consume(first: Int(timeLength)), as: UTF8.self)
        value = timeValue
    }
    
    init(_ val: String) {
        value = val
    }
}

/// A hashtable contains type for keys, type for values, number of items in hashtable (integer on 4 bytes), and then keys and values of items.
struct WCKHashtable: WCKObject {
    let type: WCKVariableType = .htb
    let keyType: WCKVariableType
    let valueType: WCKVariableType
    let count: WCKInteger
    var items: [WCKVariableType: WCKObject] = [:]
    
    init?(data: inout Data) {
        guard let newKeyType = WCKVariableType(rawValue: String(decoding:data.consume(first: 3), as: UTF8.self)) else { return nil }
        guard let newValueType = WCKVariableType(rawValue: String(decoding:data.consume(first: 3), as: UTF8.self)) else { return nil }
        
        keyType = newKeyType
        valueType = newValueType
        count = WCKInteger(data: &data)
    }
    
}

/// A hdata contains a path with hdata names, list of keys, number of set of objects, and then set of objects (path with pointers, then objects).
struct WCKHdata: WCKObject {
    let type: WCKVariableType = .hda
    
    
}

struct WCKArray: WCKObject {
    let type: WCKVariableType = .arr
    let itemType: WCKVariableType
    let length: WCKInteger
    
    
}


// MARK: It seems that the weechat documentation doesn't really do infos anymore
/// A info contains a name and a value (both are strings).
//struct WCKInfo: WCKObject {
//    let name: WCKString
//    let value: WCKString
//    let type: WCKVariableType = .inf
//    
//    init(name: WCKString, value: WCKString) {
//        self.name = name
//        self.value = value
//    }
//}

/// A infolist contains a name, number of items, and then items (set of variables).
//struct WCKInfolist: WCKObject {
//    let name: WCKString
//    let count: WCKInteger
//    let items: [WCKInfoListItem]
//    let type: WCKVariableType = .inl
//    
//}
//
///// An infolist is an item that belongs in an info list
//struct WCKInfoListItem {
//    let count: WCKInteger
//    let name: WCKString
//    let type: WCKVariableType
//    let value: WCKObject
//    
//    
//
//}
