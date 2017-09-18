//
//  Decimal.swift
//  tome2nrtm
//
//  Created by Gereon Steffens on 18.09.17.
//

import Foundation

extension NSDecimalNumber: Encodable {
    
    // division
    static func /(_ lhs: NSDecimalNumber, _ rhs: NSDecimalNumber) -> NSDecimalNumber {
        return lhs.dividing(by: rhs)
    }
    
    // add decimal
    static func +=(_ lhs: inout NSDecimalNumber, _ rhs: NSDecimalNumber) {
        lhs = lhs.adding(rhs)
    }
    
    // add int
    static func +=(_ lhs: inout NSDecimalNumber, _ rhs: Int) {
        let r = NSDecimalNumber(decimal: Decimal(rhs))
        lhs = lhs.adding(r)
    }
    
    var isNaN: Bool {
        return self == NSDecimalNumber.notANumber
    }
    
    static func >(_ lhs: NSDecimalNumber, _ rhs: NSDecimalNumber) -> Bool {
        return lhs.compare(rhs) == .orderedDescending
    }
    
    private static let round5 = NSDecimalNumberHandler(roundingMode: .plain, scale: 5, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let roundedValue = self.rounding(accordingToBehavior: NSDecimalNumber.round5)
        try container.encode(roundedValue.doubleValue)
    }
}
