//
//  SupportingTypes.swift
//
//
//  Created by James Pamplona on 9/21/23.
//

import SwiftUI


protocol ViewSpacingProtocol {
    func distance(to next: Self, along axis: Axis) -> CGFloat
    mutating func formUnion(_ other: Self, edges: Edge.Set)
    func union(_ other: Self, edges: Edge.Set) -> Self
}

extension ViewSpacing: ViewSpacingProtocol { }

protocol ViewDimensionsProtocol {
    var height: CGFloat { get }
    var width: CGFloat { get }

    subscript(guide: VerticalAlignment) -> CGFloat { get }
    subscript(guide: HorizontalAlignment) -> CGFloat { get }
    subscript(explicit guide: VerticalAlignment) -> CGFloat? { get }
    subscript(explicit guide: HorizontalAlignment) -> CGFloat? { get }

}

extension ViewDimensions: ViewDimensionsProtocol { }

protocol LayoutSubviewProtocol {
    associatedtype ViewDimensionsType: ViewDimensionsProtocol
    associatedtype ViewSpacingType: ViewSpacingProtocol
    var spacing: ViewSpacingType { get }
    var priority: Double { get }

    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize)
    func dimensions(in proposal: ProposedViewSize) -> ViewDimensionsType
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize
    subscript<K>(key: K.Type) -> K.Value where K : LayoutValueKey { get }
}

extension LayoutSubview: LayoutSubviewProtocol { }

struct Row<LayoutSubviewType: LayoutSubviewProtocol> {
    var views: [LayoutSubviewType] = []
    var spacing: Double? = nil

    var count: Int {
        views.count
    }

    private func minimumWidth(of views: [LayoutSubviewType]) -> Double {
        guard views.isEmpty == false else { return 0 }
        guard views.count > 1 else { return views[0].sizeThatFits(.unspecified).width }

        let adjacentPairs = zip(views, views.lazy.dropFirst())

        return adjacentPairs
            .enumerated()
            .reduce(0.0) { partialResult, enumeratedSubviewPairs in
                let (index, (view1, view2)) = enumeratedSubviewPairs
                var width = partialResult
                if index == 0 {
                    width += view1.sizeThatFits(.unspecified).width
                }
                let spacing = spacing ?? view1.spacing.distance(to: view2.spacing, along: .horizontal)
                width += spacing + view2.sizeThatFits(.unspecified).width

                return width
            }
    }

    func minimumWidth() -> Double {
        minimumWidth(of: views)
    }

    func minimumWidth(withView view: LayoutSubviewType) -> Double {
        minimumWidth(of: views + [view])
    }

    private func maxHeight(of views: [LayoutSubviewType]) -> Double {
        views.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
    }

    func maxHeight() -> Double {
        maxHeight(of: views)
    }

    func maxHeight(withView view: LayoutSubviewType) -> Double {
        maxHeight(of: views + [view])
    }

    func averageSpacing() -> Double {
        if let spacing { return spacing } // guard
        guard views.isEmpty == false else { return 0 }

        let adjacentPairs = zip(views, views.lazy.dropFirst())

        return adjacentPairs.map { view1, view2 in
            view1.spacing.distance(to: view2.spacing, along: .horizontal)
        }
        .reduce(0, +) / Double(views.count)
    }

    mutating func append(_ view: LayoutSubviewType) {
        views.append(view)
    }
}
