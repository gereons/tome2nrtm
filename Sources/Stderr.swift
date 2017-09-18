//
//  Stderr.swift
//  tome2nrtm
//
//  Created by Gereon Steffens on 18.09.17.
//

import Foundation

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public struct StderrOutputStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stderr) }
}
public var errStream = StderrOutputStream()

func printErr(_ str: String) {
    print(str, to: &errStream)
}

func die(_ str: String) -> Never {
    printErr(str)
    exit(1)
}
