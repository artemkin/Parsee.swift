//
//  Parsee.swift
//  Parsee
//
//  Created by Stas on 06.10.14.
//  Copyright (c) 2014 artemkin. All rights reserved.
//

import Foundation

// Kludge until non-fixed multi-payload enum layout is implemented
public final class Box<T> {
    public let unbox: T
    public init(_ value: T) { self.unbox = value }
}

public enum Result<T> {
    case Fail(String)
    case OK(Box<T>)

    public func asOptional() -> T? {
        switch self {
        case let .OK(data):
            return data.unbox
        case _:
            return nil
        }
    }
}

public struct Input {
    init(s: String) {
        self.s = s
    }

    let s: String
}

public struct Parser<T> {
    let run: Input -> (Result<T>, Input)

    public subscript(callback: T -> ()) -> Parser<T> {
        return Parser<T> { i in
            switch self.run(i) {
            case let (.OK(data), input):
                callback(data.unbox)
                return (.OK(data), input)
            case let fail:
                return fail
            }
        }
    }
}

public func return_<T>(data: T) -> Parser<T> {
    return Parser<T> { i in (.OK(Box(data)), i)}
}

public func fail<T>(msg: String) -> Parser<T> {
    return Parser<T> { i in (.Fail(msg), i)}
}

public func parse<T>(p: Parser<T>, s: String) -> Result<T> {
    switch p.run(Input(s: s)) {
    case (.OK(let data), _):
        return .OK(data)
    case (.Fail(let err), _):
        return .Fail(err)
    }
}

/// Character parsers

func satisfy(pred: Character -> Bool, errorMsg: String = "satisfy") -> Parser<Character> {
    return Parser<Character> { input in
        let s = input.s
        let ch = first(s)
        if ch != nil && pred(ch!) {
            return (.OK(Box(ch!)), Input(s: dropFirst(s)))
        }
        return (.Fail(errorMsg), input)
    }
}

func satisfyWith<T>(transform: Character -> T, pred: T -> Bool, errorMsg: String = "satisfyWith") -> Parser<T> {
    return Parser<T> { input in
        let s = input.s
        let ch = first(s)
        if ch != nil {
            let result = transform(ch!)
            if pred(result) {
                return (.OK(Box(result)), Input(s: dropFirst(s)))
            }
        }
        return (.Fail(errorMsg), input)
    }
}

func skip(p: Character -> Bool, errorMsg: String = "skip") -> Parser<()> {
    return Parser<()> { input in
        let s = input.s
        let ch = first(s)
        if ch != nil && p(ch!) {
            return (.OK(Box(())), Input(s: dropFirst(s)))
        }
        return (.Fail(errorMsg), input)
    }
}

let anyChar = Parser<Character> { input in
    let s = input.s
    if let ch = first(s) {
        return (.OK(Box(ch)), Input(s: dropFirst(s)))
    }
    return (.Fail("anyChar"), input)
}

public func char(ch: Character) -> Parser<Character> {
    return satisfy({ $0 == ch }, errorMsg: "char")
}

func skipChar(ch: Character) -> Parser<()> {
    return skip({ $0 == ch }, errorMsg: "skipChar")
}


/// String parsers

func take(n: Int, errorMsg: String = "take") -> Parser<String> {
    assert(n > 0)
    if n < 1 {
        return Parser<String> { (.Fail("wrong usage of \"\(errorMsg)\" parser"), $0) }
    }

    return Parser<String> { input in
        let s = input.s
        let index = advance(s.startIndex, n - 1, s.endIndex)
        if index != s.endIndex {
            return (.OK(Box(s[s.startIndex...index])), Input(s: s[index.successor()..<s.endIndex]))
        }
        return (.Fail(errorMsg), input)
    }
}

func takeWith<T>(n: Int, transform: String -> T, pred: T -> Bool, errorMsg: String = "takeWith") -> Parser<T> {
    assert(n > 0)
    if n < 1 {
        return Parser<T> { (.Fail("wrong usage of \"\(errorMsg)\" parser"), $0) }
    }

    return Parser<T> { input in
        let s = input.s
        let index = advance(s.startIndex, n - 1, s.endIndex)
        if index != s.endIndex {
            let result = transform(s[s.startIndex...index])
            if (pred(result)) {
                return (.OK(Box(result)), Input(s: s[index.successor()..<s.endIndex]))
            }
        }
        return (.Fail(errorMsg), input)
    }
}

func takeWith(n: Int, pred: String -> Bool, errorMsg: String = "takeWith") -> Parser<String> {
    return takeWith(n, { $0 }, pred, errorMsg: errorMsg)
}


func string(str: String) -> Parser<String> {
    return Parser<String> { input in
        let s = input.s
        if let index = matchPrefix(str, s) {
            return (.OK(Box(str)), Input(s: s[index..<s.endIndex]))
        }
        return (.Fail("string"), input)
    }
}

func takeWhile(pred: Character -> Bool) -> Parser<String> {
    return Parser<String> { input in
        let s = input.s
        let index = iterateWhile(s, pred)
        return (.OK(Box(s[s.startIndex..<index])), Input(s: s[index..<s.endIndex]))
    }
}

// TODO: get rid of redundant closure
func takeWhile1(pred: Character -> Bool) -> Parser<String> {
    return Parser<String> { input in
        let s = input.s
        var some = false
        let index = iterateWhile(s) { ch in
            let result = pred(ch)
            some |= result
            return result
        }
        if (some) {
            return (.OK(Box(s[s.startIndex..<index])), Input(s: s[index..<s.endIndex]))
        }
        return (.Fail("tailWhile1"), input)
    }
}

func takeTill(pred: Character -> Bool) -> Parser<String> {
    return takeWhile { !pred($0) }
}

func takeTill(ch: Character) -> Parser<String> {
    return takeWhile { $0 != ch }
}

let takeText = Parser<String> { input in
    return (.OK(Box(input.s)), Input(s: ""))
}

func scan<T>(var state: T, f: (T, Character) -> T?) -> Parser<String> {
    return Parser<String> { input in
        let s = input.s
        var index = s.startIndex
        while index != s.endIndex {
            if let result = f(state, s[index]) {
                state = result
            } else {
                break;
            }
            index = index.successor()
        }
        return (.OK(Box(s[s.startIndex..<index])), Input(s: s[index..<s.endIndex]))
    }
}

// TODO: REMOVE COPY PASTE
func runScanner<T>(var state: T, f: (T, Character) -> T?) -> Parser<(String, T)> {
    return Parser<(String, T)> { input in
        let s = input.s
        var index = s.startIndex
        while index != s.endIndex {
            if let result = f(state, s[index]) {
                state = result
            } else {
                break;
            }
            index = index.successor()
        }
        let t = (s[s.startIndex..<index], state)
        return (.OK(Box(t)), Input(s: s[index..<s.endIndex]))
    }
}


///////////////////////////////////////////////////////////////////////////////
// Numeric parsers

protocol ErrorMsg {
    class var errorMsg: String { get }
}

func generateUnsignedParser<T: protocol<UnsignedIntegerTypeEx, ErrorMsg>>() -> Parser<T> {
    return Parser<T> { input in
        switch takeWhile1(isDigit).run(input) {
        case let (.OK(data), input):
            if let num: T = data.unbox.toUnsignedT() {
                return (.OK(Box(num)), input)
            } else {
                return (.Fail(T.errorMsg), input)
            }
        case let (.Fail(msg), input):
            return (.Fail(msg), input)
        }
    }
}

extension UInt:   ErrorMsg { static var errorMsg = "uint"   }
extension UInt8:  ErrorMsg { static var errorMsg = "uint8"  }
extension UInt16: ErrorMsg { static var errorMsg = "uint16" }
extension UInt32: ErrorMsg { static var errorMsg = "uint32" }
extension UInt64: ErrorMsg { static var errorMsg = "uint64" }

public let uint:   Parser<UInt>   = generateUnsignedParser()
public let uint8:  Parser<UInt8>  = generateUnsignedParser()
public let uint16: Parser<UInt16> = generateUnsignedParser()
public let uint32: Parser<UInt32> = generateUnsignedParser()
public let uint64: Parser<UInt64> = generateUnsignedParser()


