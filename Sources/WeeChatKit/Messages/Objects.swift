//
//  Objects.swift
//
//
//  Created by Michael Eisemann on 6/10/23.
//

import Foundation


enum WCKVariable: CustomStringConvertible {
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
struct WCKChar {
    let value: Int8
    let type: WCKVariable = .chr
}

/// Signed 32-bit (4 byte) integers, encoded as big-endian (most significant byte first)
struct WCKInteger {
    let value: Int32
    let type: WCKVariable = .int
    
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
struct WCKLongInteger {
    let value: Int64
    let type: WCKVariable = .lon
    
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
struct WCKString {
    let value: String?
    let type: WCKVariable = .str
    
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
struct WCKBuffer {
    let value: [UInt8]?
    let type: WCKVariable = .buf
    
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
struct WCKPointer {
    let value: String
    let type: WCKVariable = .ptr
    
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
struct WCKTime {
    let value: String
    let type: WCKVariable = .tim
    
    init(size: Int, data: inout Data) {
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
struct WCKHashtable {
}

/// A hdata contains a path with hdata names, list of keys, number of set of objects, and then set of objects (path with pointers, then objects).
struct WCKHdata {}


/// A info contains a name and a value (both are strings).
struct WCKInfo {
    let name: WCKString
    let value: WCKString
    let type: WCKVariable = .inf
    
    init(name: WCKString, value: WCKString) {
        self.name = name
        self.value = value
    }
}

/// A infolist contains a name, number of items, and then items (set of variables).
struct WCKInfolist {
    let name: WCKString
    let count: WCKInteger
    let type: WCKVariable = .inl
    
}

/// An infolist is an item that belongs in an info list
struct WCKInfoListItem {
    let count: WCKInteger
    let name: WCKString
    let type: WCKVariable
}
