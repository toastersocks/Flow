//
//  +Arbitrary.swift
//  
//
//  Created by James Pamplona on 9/2/23.
//

import CoreGraphics
import SwiftCheck
@testable import Flow


extension CGSize: Arbitrary {
    public static var arbitrary: Gen<CGSize> {
        Gen<CGSize>.compose { composer in
            CGSize(width: composer.generate(using: Double.arbitrary.suchThat { $0 >= 0 && $0 <= 410 }),
                   height: composer.generate(using: Double.arbitrary.suchThat { $0 >= 0 && $0 <= 1000 }))
        }
    }
}

extension CGFloat: Arbitrary {
    public static var arbitrary: Gen<CGFloat> {
        Gen<CGFloat>.compose { composer in
            CGFloat(Double.arbitrary.generate)
        }
    }
}

extension MockLayoutSubview: Arbitrary {
    public static var arbitrary: Gen<MockLayoutSubview> {
        Gen<MockLayoutSubview>.compose { composer in
            MockLayoutSubview(spacing: MockViewSpacing(),
                              priority: 0,
                              width: composer.generate(using: Double.arbitrary.suchThat { $0 >= 0 && $0 <= 410 }),
                              height: composer.generate(using: Double.arbitrary.suchThat { $0 >= 0 && $0 <= 1000 }))
        }
    }
}

extension Flow.Alignment: Arbitrary {
    public static var arbitrary: Gen<Flow.Alignment> {
        Gen<Flow.Alignment>.fromElements(of: [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing, .center, .centerJustify, .centerDistribute])
    }
}
