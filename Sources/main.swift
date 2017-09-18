// tome2nrtm

import Foundation

let separator = "^^THIS IS A SEPARATOR^^"

let cmdline = CommandLine.arguments

if cmdline.count != 2 {
    die("usage: tome2nrtm inputfile")
}

let inputFile = cmdline[1]
let fileUrl = URL(fileURLWithPath: inputFile)
guard let data = try? Data(contentsOf: fileUrl) else {
    die("cannot open input file \(inputFile)")
}

var rawStr: String?
if let s = String(bytes: data, encoding: .utf8) {
    rawStr = s
} else if let s = String(bytes: data, encoding: .isoLatin1) {
    rawStr = s
}

guard let str = rawStr else {
    die("input file is neither utf-8 nor latin-1 encoded")
}

guard let range = str.range(of: separator) else {
    die("input file does not contain required separator")
}

// strip the separator off the end of the input
let jsonStr = String(str[..<range.lowerBound])
if let data = jsonStr.data(using: .utf8), let tome = TOME.create(from: data) {
    let nrtmTournament = NRTM.Tournament.create(from: tome)
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    
    let data = try encoder.encode(nrtmTournament)
    
    if let str = String(bytes: data, encoding: .utf8) {
        print(str)
    }
} else {
    die("unsupported input file format")
}

