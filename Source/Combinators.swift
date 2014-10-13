//
//  Combinators.swift
//  Parsee
//
//  Created by Stas on 10.10.14.
//  Copyright (c) 2014 artemkin. All rights reserved.
//

import Foundation

// bind
infix operator >>- { associativity left }
public func >>-<A, B>(a: Parser<A>, f: A -> Parser<B>) -> Parser<B> {
    return Parser<B> { i in
        switch a.run(i) {
        case let (.OK(data), input):
            return f(data.unbox).run(input)
        case let (.Fail(msg), input):
            return (.Fail(msg), input)
        }
    }
}

// map
infix operator >>| { associativity left }
public func >>|<A, B>(a: Parser<A>, f: A -> B) -> Parser<B> {
    return a >>- { a in return_(f(a)) }
}

/* TODO: existing operator.
// sequence (discard first result)
infix operator >> { associativity left }
func >><A, B>(a: Parser<A>, b: Parser<B>) -> Parser<B> {
    return a >>= { _ in b }
}*/

infix operator <|> { associativity left }
public func <|><T>(a: Parser<T>, b: Parser<T>) -> Parser<T> {
    return Parser<T> { i in
        switch a.run(i) {
        case let (.OK(data), input):
            return (.OK(data), input)
        default:
            return b.run(i)
        }
    }
}


// fmap or <$>
infix operator <^> { associativity left }
public func <^><A, B>(f: A -> B, a: Parser<A>) -> Parser<B> {
    return Parser<B> { i in
        switch a.run(i) {
        case let (.OK(data), input):
            return (.OK(Box(f(data.unbox))), input)
        case let (.Fail(msg), input):
            return (.Fail(msg), input)
        }
    }
}

/* TODO: TO IMPLEMENT
// apply
// Sequential application
infix operator <*> { associativity left }
func <*><A, B>(f: Parser<A -> B>, a: Parser<A>) -> Parser<B> {
}
*/

// Sequence actions, discarding the value of the first argument.
infix operator *> { associativity left }
public func *><A, B>(a: Parser<A>, b: Parser<B>) -> Parser<B> {
    return a >>- { _ in b }
}

// Sequence actions, discarding the value of the second argument.
infix operator <* { associativity left }
public func <*<A, B>(a: Parser<A>, b: Parser<B>) -> Parser<A> {
    return Parser<A> { i in
        switch a.run(i) {
        case let (.OK(data), input):
            switch b.run(input) {
            case let(.OK(_), input):
                return (.OK(data), input)
            case let (.Fail(msg), input):
                return (.Fail(msg), input)
            }
        case let (.Fail(msg), input):
            return (.Fail(msg), input)
        }
    }
}
