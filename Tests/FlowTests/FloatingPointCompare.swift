//
//  FloatingPointCompare.swift
//  
//
//  Created by James Pamplona on 9/3/23.
//

import CoreGraphics


// We want to consider floats that are extremely (for our purposes) close in value (i.e. a rounding error) to be considered equal.
extension CGFloat {
    func isEqual(to other: Self, tolerance: Self) -> Bool {
        abs(self - other) < tolerance
    }

    func isNearlyEqual(to other: Self) -> Bool {
        isEqual(to: other, tolerance: 0.00000000001)
    }
}

extension CGSize {
    func isNearlyEqual(to other: Self) -> Bool {
        width.isNearlyEqual(to: other.width) && height.isNearlyEqual(to: other.height)
    }
}

extension CGPoint {
    func isNearlyEqual(to other: Self) -> Bool {
        x.isNearlyEqual(to: other.x) && y.isNearlyEqual(to: other.y)
    }
}

extension CGRect {
    func isNearlyEqual(to other: Self) -> Bool {
        origin.isNearlyEqual(to: other.origin) && size.isNearlyEqual(to: other.size)
    }
}
