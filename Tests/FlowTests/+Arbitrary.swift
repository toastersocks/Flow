//
//  +Arbitrary.swift
//  
//
//  Created by James Pamplona on 9/2/23.
//

import CoreGraphics
import SwiftCheck

extension CGSize: Arbitrary {
    public static var arbitrary: SwiftCheck.Gen<CGSize> {
        Gen<CGSize>.compose { composer in
            CGSize(width: composer.generate(using: Double.arbitrary.suchThat { $0 >= 0 && $0 <= 410 }),
                   height: composer.generate(using: Double.arbitrary.suchThat { $0 >= 0 && $0 <= 1000 }))
        }
    }
}
