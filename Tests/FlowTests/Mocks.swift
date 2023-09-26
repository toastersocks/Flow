//
//  Mocks.swift
//  
//
//  Created by James Pamplona on 9/25/23.
//

import SwiftUI
@testable import Flow


struct MockViewSpacing: ViewSpacingProtocol {
    var preferredHorizontalDistance = 7.0
    var preferredVerticalDistance = 10.0

    func distance(to next: Self, along axis: Axis) -> CGFloat {
        switch axis {
        case .horizontal: max(preferredHorizontalDistance, next.preferredHorizontalDistance)
        case .vertical: max(preferredVerticalDistance, next.preferredVerticalDistance)
        }
    }

    mutating func formUnion(_ other: Self, edges: Edge.Set) {
        if edges.contains(.horizontal) {
            preferredHorizontalDistance = max(preferredHorizontalDistance, other.preferredHorizontalDistance)
        }
        if edges.contains(.vertical) {
            preferredVerticalDistance = max(preferredVerticalDistance, other.preferredVerticalDistance)
        }
    }

    func union(_ other: Self, edges: Edge.Set) -> Self {
        MockViewSpacing(preferredHorizontalDistance: edges.contains(.horizontal) ? max(preferredHorizontalDistance, other.preferredHorizontalDistance) : preferredHorizontalDistance, preferredVerticalDistance: edges.contains(.vertical) ? max(preferredVerticalDistance, other.preferredVerticalDistance) : preferredVerticalDistance)
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
        case .listRowSeparatorLeading: .zero
        case .listRowSeparatorTrailing: width
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
        case .listRowSeparatorLeading: .zero
        case .listRowSeparatorTrailing: width
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
