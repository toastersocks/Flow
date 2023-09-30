//
//  Mocks.swift
//  
//
//  Created by James Pamplona on 9/25/23.
//

import SwiftUI
@testable import Flow


struct MockViewSpacing: ViewSpacingProtocol, Hashable {
    static var zero: MockViewSpacing { MockViewSpacing(horizontalSpacing: .zero, verticalSpacing: .zero) }
    var horizontalSpacing = 7.0
    var verticalSpacing = 10.0

    init(horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    init() { }

    func distance(to next: Self, along axis: Axis) -> CGFloat {
        switch axis {
        case .horizontal: max(horizontalSpacing, next.horizontalSpacing)
        case .vertical: max(verticalSpacing, next.verticalSpacing)
        }
    }

    mutating func formUnion(_ other: Self, edges: Edge.Set) {
        if edges.contains(.horizontal) {
            horizontalSpacing = max(horizontalSpacing, other.horizontalSpacing)
        }
        if edges.contains(.vertical) {
            verticalSpacing = max(verticalSpacing, other.verticalSpacing)
        }
    }

    func union(_ other: Self, edges: Edge.Set) -> Self {
        let containsHorizontal = edges.contains(.horizontal) || edges.contains(.leading) || edges.contains(.trailing) || edges.contains(.all)
        let containsVertical = edges.contains(.vertical) || edges.contains(.top) || edges.contains(.bottom) || edges.contains(.all)

        return MockViewSpacing(horizontalSpacing: containsHorizontal ? max(horizontalSpacing, other.horizontalSpacing) : horizontalSpacing, verticalSpacing: containsVertical ? max(verticalSpacing, other.verticalSpacing) : verticalSpacing)
    }
}

struct MockViewDimensions: ViewDimensionsProtocol {
    var height: CGFloat
    var width: CGFloat

    subscript(guide: VerticalAlignment) -> CGFloat {
        switch guide {
        case .bottom: height
        case .top: .zero
        case .center: height * 0.5
        case .firstTextBaseline: .zero
        case .lastTextBaseline: height
        default: height * 0.5
        }
    }

    subscript(guide: HorizontalAlignment) -> CGFloat {
        switch guide {
        case .trailing: width
        case .leading: .zero
        case .center: width * 0.5
        #if !os(watchOS) && !os(tvOS)
        case .listRowSeparatorLeading: .zero
        case .listRowSeparatorTrailing: width
        #endif
        default: width * 0.5
        }
    }

    subscript(explicit guide: VerticalAlignment) -> CGFloat? {
        switch guide {
        case .bottom: height
        case .top: .zero
        case .center: height * 0.5
        case .firstTextBaseline: .zero
        case .lastTextBaseline: height
        default: height * 0.5
        }
    }

    subscript(explicit guide: HorizontalAlignment) -> CGFloat? {
        switch guide {
        case .trailing: width
        case .leading: .zero
        case .center: width * 0.5
        #if !os(watchOS) && !os(tvOS)
        case .listRowSeparatorLeading: .zero
        case .listRowSeparatorTrailing: width
        #endif
        default: width * 0.5
        }
    }
}

struct MockLayoutSubview: LayoutSubviewProtocol {
    var spacing: MockViewSpacing
    var priority: Double

    var width: Double
    var height: Double

    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize) {
        assertionFailure("Not implemented")
    }

    func dimensions(in proposal: ProposedViewSize) -> MockViewDimensions {
        MockViewDimensions(height: height, width: width)
    }

    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        CGSize(width: width, height: height)
    }

    subscript<K>(key: K.Type) -> K.Value where K: LayoutValueKey {
        key.defaultValue
    }
}
