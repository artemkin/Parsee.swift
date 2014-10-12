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

    func test_uintParser() {
        XCTAssert(testParser("", uint, nil))
        XCTAssert(testParser("0", uint, 0))
        XCTAssert(testParser("1", uint, 1))
        XCTAssert(testParser("-1", uint, nil))
        XCTAssert(testParser("+1", uint, nil))
        XCTAssert(testParser("12345 test", uint, 12345))
        XCTAssert(testParser(String(UInt.max), uint, UInt.max))
        XCTAssert(testParser("18446744073709551616", uint, nil))
    }
}
