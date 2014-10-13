//
//  StringUtils.swift
//  Parsee
//
//  Created by Stas on 06.10.14.
//  Copyright (c) 2014 artemkin. All rights reserved.
//

import Foundation

public func isHorizontalSpace(ch: Character) -> Bool {
    return ch == " " || ch == "\t"
}

public func isDigit(ch: Character) -> Bool {
    return ch >= "0" && ch <= "9"
}

public func isDigit(ch: UnicodeScalar) -> Bool {
    let num = ch.value
    return num >= 0x30 && num <= 0x39
}

public func matchPrefix(prefix: String, s: String) -> String.Index? {
    var prefixIndex = prefix.startIndex
    var sIndex = s.startIndex
    while prefixIndex != prefix.endIndex && sIndex != s.endIndex {
        if prefix[prefixIndex] != s[sIndex] {
            return nil
        }
        prefixIndex = prefixIndex.successor()
        sIndex = sIndex.successor()
    }
    return prefixIndex != prefix.endIndex ? nil : sIndex
}

public func iterateWhile(s: String, pred: Character -> Bool) -> String.Index {
    var index = s.startIndex
    while index != s.endIndex && pred(s[index]) {
        index = index.successor()
    }
    return index
}

protocol UnsignedIntegerTypeEx: UnsignedIntegerType {
    class var max: Self { get }
    init(_: UInt32)
}
extension UInt:   UnsignedIntegerTypeEx {}
extension UInt8:  UnsignedIntegerTypeEx {}
extension UInt16: UnsignedIntegerTypeEx {}
extension UInt32: UnsignedIntegerTypeEx {}
extension UInt64: UnsignedIntegerTypeEx {}

extension String {
    
    /// If the string represents an integer that fits into an UInt, returns
    /// the corresponding integer.  This accepts strings that match the regular
    /// expression "[0-9]+" only.
    public func toUInt()   -> UInt?   { return toUnsignedT() }
    public func toUInt8()  -> UInt8?  { return toUnsignedT() }
    public func toUInt16() -> UInt16? { return toUnsignedT() }
    public func toUInt32() -> UInt32? { return toUnsignedT() }
    public func toUInt64() -> UInt64? { return toUnsignedT() }

    func toUnsignedT<T: UnsignedIntegerTypeEx>() -> T? {
        if self.isEmpty {
            return nil
        }

        let maxDiv10 = T.max / 10

        var x: T = 0
        for ch in self.unicodeScalars {
            let value = ch.value
            if value < 0x30 || value > 0x39 || x > maxDiv10 {
                return nil
            }
            x *= 10
            let num = T(value - 0x30)
            if x > (T.max - num) {
                return nil
            }
            x += num
        }
        return x
    }
    
}
