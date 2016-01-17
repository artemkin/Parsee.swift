
## Monadic parser combinators in Swift (INCOMPLETE)

### Experiment

Read the sources of [`attoparsec`](https://github.com/bos/attoparsec) library, and see how it might be translated to Swift.

### Results

- It is pretty hard to follow CPS-style code in Haskell
- Swift operators are messy
- My incomplete library is able to parse IP address :)

```
    enum IP { case IP(UInt8, UInt8, UInt8, UInt8) }

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
```
