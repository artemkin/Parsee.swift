//
//  ParseeTests.swift
//  ParseeTests
//
//  Created by Stas on 06.10.14.
//  Copyright (c) 2014 artemkin. All rights reserved.
//

import Cocoa
import XCTest
import Parsee

func testParser<T: Equatable>(input: String, parser: Parser<T>, expectedOpt: T?) -> Bool {
    if let result = parse(parser, input).asOptional() {
        if let expected = expectedOpt {
            return result == expected
        } else {
            return false
        }
    }
    return expectedOpt == nil
}

enum IP { case IP(UInt8, UInt8, UInt8, UInt8) }
extension IP: Equatable {}
func ==(lhs: IP, rhs: IP) -> Bool {
    switch((lhs, rhs)) {
    case let (.IP(l1, l2, l3, l4), .IP(r1, r2, r3, r4)):
        return l1 == r1 && l2 == r2 && l3 == r3 && l4 == r4
    }
}

class ParseeTests: XCTestCase {

    func test_matchPrefix() {
        func test(prefix: String, s: String, rest: String?) -> Bool {
            if let index = matchPrefix(prefix, s) {
                return rest! == s[index..<s.endIndex]
            } else {
                return rest == nil
            }
        }

        XCTAssert(test("", "", ""))
        XCTAssert(test("", "a", "a"))
        XCTAssert(test("a", "", nil))
        XCTAssert(test("a", "a", ""))
        XCTAssert(test("a", "ab", "b"))
        XCTAssert(test("ab", "ab", ""))
        XCTAssert(test("ab", "abc", "c"))
        XCTAssert(test("ab", "abcd", "cd"))
        XCTAssert(test("aa", "abcd", nil))
        XCTAssert(test("abcd", "abc", nil))
    }

    func test_stringToUInt() {
        XCTAssert("".toUInt() == nil)
        XCTAssert(" ".toUInt() == nil)
        XCTAssert(" 1".toUInt() == nil)
        XCTAssert("1 ".toUInt() == nil)
        XCTAssert("-1".toUInt() == nil)
        XCTAssert("0".toUInt() == 0)
        XCTAssert("11".toUInt() == 11)
        XCTAssert("12345".toUInt() == 12345)
        XCTAssert(String(UInt.max).toUInt() == UInt.max)
        XCTAssert(String(UInt.min).toUInt() == UInt.min)
        XCTAssert("18446744073709551620".toUInt() == nil) // 18446744073709551620 / 10 * 10 > UInt.max
        XCTAssert("18446744073709551616".toUInt() == nil) // UInt.max + 1
    }

    func test_stringToInt() {
        XCTAssert("".toInt8() == nil)
        XCTAssert(" ".toInt8() == nil)
        XCTAssert("-".toInt8() == nil)
        XCTAssert("+".toInt8() == nil)
        XCTAssert(" 1".toInt8() == nil)
        XCTAssert("1 ".toInt8() == nil)
        XCTAssert("-1".toInt8() == -1)
        XCTAssert("+1".toInt8() == 1)
        XCTAssert("0".toInt8() == 0)
        XCTAssert("11".toInt8() == 11)
        XCTAssert("11.".toInt8() == nil)
        XCTAssert("123".toInt8() == 123)
        XCTAssert("-123".toInt8() == -123)
        XCTAssert("-130".toInt8() == nil)
        XCTAssert("130".toInt8() == nil)
        XCTAssert(String(Int8.max).toInt8() == Int8.max)
        XCTAssert(String(Int8.min).toInt8() == Int8.min)
    }

    func test_uintParser() {
        XCTAssert(testParser("", uint8, nil))
        XCTAssert(testParser("-", uint8, nil))
        XCTAssert(testParser("+", uint8, nil))
        XCTAssert(testParser("-1", uint8, nil))
        XCTAssert(testParser("+1", uint8, nil))
        XCTAssert(testParser("0", uint8, 0))
        XCTAssert(testParser("123", uint8, 123))
        XCTAssert(testParser("00000000000123", uint8, 123))
        XCTAssert(testParser("255", uint8, 255))
        XCTAssert(testParser("256", uint8, nil))

        XCTAssert(testParser("", uint, nil))
        XCTAssert(testParser("0", uint, 0))
        XCTAssert(testParser("1", uint, 1))
        XCTAssert(testParser("-1", uint, nil))
        XCTAssert(testParser("+1", uint, nil))
        XCTAssert(testParser("12345 test", uint, 12345))
        XCTAssert(testParser(String(UInt.max), uint, UInt.max))
        XCTAssert(testParser("18446744073709551616", uint, nil))
    }

    func test_parsingIPAddress() {

        let parseIP =
            uint8     >>- { d1 in
            char(".") *>
            uint8     >>- { d2 in
            char(".") *>
            uint8     >>- { d3 in
            char(".") *>
            uint8     >>- { d4 in
                return_(IP.IP(d1, d2, d3, d4))
            }}}}

        XCTAssert(testParser("192.168.0.1", parseIP, IP.IP(192,168,0,1)))
    }
}
