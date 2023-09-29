import SwiftUI


/// A Flow layout arranges its subviews in a line, wrapping at the edge and starting new lines as needed, similar to how words wrap in a paragraph.
public struct Flow: Layout {
    /// The alignment of the subviews within the container.
    let alignment: Alignment
    /// The space between subviews.
    let spacing: CGFloat?


    /// Creates an instance with the given alignment and spacing.
    /// - Parameters:
    ///   - alignment: The alignment guide for aligning the subviews in the flow.
    ///   - spacing: The distance between subviews. This spacing is not applied before the first, or after the last view in a row.
    public init(alignment: Alignment = .topLeading, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }

    /// Computes the overall size required to fit an array of subview sizes, based on a proposed view size.
    /// - Parameters:
    ///   - proposal: The proposed size offered to place views.
    ///   - subviewSizes: An array of sizes for which to calculate the bounding box.
    /// - Returns: A `CGSize` representing the bounding box containing the placed sizes.
    func sizeThatFits<LayoutSubviewType: LayoutSubviewProtocol>(proposal: ProposedViewSize, subviews: [LayoutSubviewType]) -> CGSize {
        if proposal.width == .infinity, proposal.height == .infinity {
            return CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        }

        let totalChildWidthWithSpacing = Row(views: subviews, spacing: spacing).minimumWidth()

        let minimumParentWidth = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0

        let boundsWidth = max(proposal.width ?? totalChildWidthWithSpacing, minimumParentWidth)

        var currentPoint = CGPoint(x: 0, y: 0)

        var maxX: CGFloat = 0
        var maxY: CGFloat = 0

        var previousRow: Row<LayoutSubviewType>? = nil
        var currentRow = Row<LayoutSubviewType>(views: [], spacing: spacing)

        for currentSubview in subviews {
            let rowBoundsDifference = currentRow.minimumWidth(withView: currentSubview) - boundsWidth
            let wouldOverflow = rowBoundsDifference > 0.000_000_000_001

            if wouldOverflow {
                maxX = max(maxX, currentRow.minimumWidth())
                previousRow = currentRow
                currentRow = Row(views: [currentSubview], spacing: spacing)
                let verticalSpacing = previousRow.map { currentRow.spacing(to: $0) } ?? 0

                currentPoint.y += verticalSpacing + (previousRow?.maxHeight() ?? 0)

            } else {
                currentRow.append(currentSubview)
            }
            maxX = max(maxX, currentRow.minimumWidth())
            maxY = max(maxY, currentPoint.y + currentRow.maxHeight())
        }

        let idealSize = CGSize(width: maxX, height: maxY)

        return idealSize
    }
    /// Returns the size that fits the subviews within the proposed size. Fulfills [SwiftUI.Layout](https://developer.apple.com/documentation/swiftui/layout) protocol requirements. See [`sizeThatFits(proposal:subviews:cache)`](https://developer.apple.com/documentation/swiftui/layout/sizethatfits(proposal:subviews:cache:)) for more info.
    @_documentation(visibility: internal)
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        sizeThatFits(proposal: proposal, subviews: subviews.map { $0 })
    }


    /// Determines the layout rectangles for a set of sizes within the given bounds, based on the flow's alignment and spacing.
    /// - Parameters:
    ///   - bounds: The bounds in which to place the sizes.
    ///   - sizes: An array of sizes for which to calculate placement.
    /// - Returns: An array of `CGRect` representing the placed sizes. The origins of the rects are normalized to the top-left of the rects. The bounding box encompassing the full extents of the rects can be found by performing a union of all the rects.
    func getRects<LayoutSubviewType: LayoutSubviewProtocol>(for subviews: [LayoutSubviewType], in bounds: CGRect) -> [CGRect] {
        var viewRects: [CGRect] = []

        func place(view: some LayoutSubviewProtocol, at point: CGPoint, anchor: UnitPoint) {
            let size = view.sizeThatFits(.unspecified)
            let topLeft = CGPoint(x: point.x - size.width * anchor.x, y: point.y - size.height * anchor.y)
            let normalizedRect = CGRect(origin: topLeft, size: size)

            viewRects.append(normalizedRect)
        }

        var currentPoint = CGPoint(x: bounds.minX, y: bounds.minY)

        var previousRow: Row<LayoutSubviewType>? = nil
        var currentRow = Row<LayoutSubviewType>(spacing: spacing)

        for (subviewIndex, currentSubview) in subviews.enumerated() {
            let currentViewSize = currentSubview.sizeThatFits(.unspecified)
            let rowBoundsDifference = currentPoint.x + currentRow.minimumWidth(withView: currentSubview) - bounds.maxX

            let wouldOverflow = rowBoundsDifference > 0.000_000_000_001
            let isLast = subviewIndex == subviews.indices.last

            if wouldOverflow || isLast {
                if !wouldOverflow {
                    currentRow.append(currentSubview)
                }

                let totalRowWidth = currentRow.minimumWidth()
                let totalRowHeight = currentRow.maxHeight()

                let unusedHorizontalSpace = bounds.maxX - totalRowWidth
                var subviewAnchor: UnitPoint = .topLeading

                switch alignment {
                case .bottomLeading:
                    currentPoint.y += totalRowHeight
                    subviewAnchor = .bottomLeading
                    fallthrough
                case .topLeading, .centerJustify:
                    currentPoint.x = bounds.minX
                case .bottomTrailing:
                    currentPoint.y += totalRowHeight
                    subviewAnchor = .bottomLeading
                    fallthrough
                case .topTrailing:
                    currentPoint.x = bounds.minX + unusedHorizontalSpace
                case .center:
                    currentPoint.x = bounds.minX + unusedHorizontalSpace * 0.5
                case .centerDistribute:
                    let spacing = currentRow.averageSpacing()
                    if unusedHorizontalSpace > spacing * 2 {
                        let distributedUnusedHorizontalSpace = (unusedHorizontalSpace - spacing * 2) / CGFloat(currentRow.count + 1)
                        currentPoint.x += distributedUnusedHorizontalSpace + spacing
                    } else {
                        currentPoint.x = bounds.minX + min(unusedHorizontalSpace * 0.5, spacing)
                    }
                }

                for rowSubview in currentRow.views {
                    if alignment == .center || alignment == .centerDistribute || alignment == .centerJustify {
                        currentPoint.y += (totalRowHeight - rowSubview.sizeThatFits(.unspecified).height) * 0.5
                    }

                    place(view: rowSubview, at: currentPoint, anchor: subviewAnchor)

                    if alignment == .center || alignment == .centerDistribute || alignment == .centerJustify  {
                        currentPoint.y -= (totalRowHeight - rowSubview.sizeThatFits(.unspecified).height) * 0.5
                    }

                    let horizontalSpacing: CGFloat

                    let spacing = currentRow.averageSpacing()

                    switch alignment {
                    case .centerDistribute where unusedHorizontalSpace > spacing * 2:
                        let distributedUnusedHorizontalSpace = (unusedHorizontalSpace - spacing * 2) / CGFloat(currentRow.count + 1)
                        horizontalSpacing = distributedUnusedHorizontalSpace + spacing
                    case .centerJustify:
                        horizontalSpacing = spacing + unusedHorizontalSpace / CGFloat(currentRow.count - 1)
                    default:
                        horizontalSpacing = spacing
                    }

                    currentPoint.x += rowSubview.sizeThatFits(.unspecified).width + horizontalSpacing
                }

                currentPoint.x = bounds.minX
                previousRow = currentRow
                currentRow = Row(views: [currentSubview], spacing: spacing)
                let verticalSpacing = previousRow.map { currentRow.spacing(to: $0) } ?? 0
                currentPoint.y += (subviewAnchor == .topLeading ? totalRowHeight : 0) + verticalSpacing
                currentRow = Row(views: [currentSubview], spacing: spacing)

                if isLast && wouldOverflow {
                    switch alignment {
                    case .bottomLeading:
                        currentPoint.y += currentViewSize.height
                        fallthrough
                    case .topLeading, .centerJustify:
                        currentPoint.x = bounds.minX
                    case .bottomTrailing:
                        currentPoint.y += currentViewSize.height
                        fallthrough
                    case .topTrailing:
                        let unusedHorizontalSpace = bounds.maxX - currentViewSize.width
                        currentPoint.x = bounds.minX + unusedHorizontalSpace
                    case .center, .centerDistribute:
                        let unusedHorizontalSpace = bounds.maxX - currentViewSize.width
                        currentPoint.x = bounds.minX + unusedHorizontalSpace * 0.5
                    }
                    place(view: currentSubview, at: currentPoint, anchor: subviewAnchor)
                }
            } else {
                currentRow.append(currentSubview)
            }
        }

        return viewRects
    }

    /// Places the subviews of the layout. Fulfills [`SwiftUI.Layout`](https://developer.apple.com/documentation/swiftui/layout) protocol requirements. See [`placeSubviews(in:proposal:subviews:cache:)`](https://developer.apple.com/documentation/swiftui/layout/placeSubviews(in:proposal:subviews:cache:)) for more info.
    @_documentation(visibility: internal)
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let viewRects = getRects(for: subviews.map { $0 },
                              in: bounds)

        for (subview, rect) in zip(subviews, viewRects) {
            subview.place(at: rect.origin, anchor: .topLeading, proposal: .unspecified)
        }
    }

    /// The alignment of subviews within the flow.
    public enum Alignment: CaseIterable {
        /// Aligns the tops of subviews within a row. Rows are flush with the leading edge of the container.
        case topLeading
        /// Aligns the tops of subviews within a row. Rows are flush with the trailing edge of the container.
        case topTrailing
        /// Aligns the bottoms of subviews within a row. Rows are flush with the leading edge of the container.
        case bottomLeading
        /// Aligns the bottoms of subviews within a row. Rows are flush with the trailing edge of the container.
        case bottomTrailing
        /// Centers subviews horizontally within a row. Rows are centered within the container. Extra space is added equally before the first subview and after the last.
        case center
        /// Centers subviews horizontally within a row. Rows are centered within the container. Extra space is first added equally before the first and after the last subviews up to the spacing amount, then distributed evenly between and around the subviews.
        case centerDistribute
        /// Aligns the horizontal centers of subviews within a row. The first subview aligns with the leading edge and the last subview aligns with the trailing edge of the container. Extra space is distributed evenly between subviews. This is similar to how justified text is laid out in a paragraph.
        case centerJustify
    }
}

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}

#if DEBUG
#Preview("System Spacing") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow {
            ForEach(0..<20) { _ in
                Color.rainbow.random()
                    .frame(width: .random(in: 40...200).rounded(),
                           height: .random(in: 30...90).rounded())
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
    .previewDisplayName("Trailing Random sizes")
}

#Preview("Leading Shuffled") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(spacing: 7) {
            ForEach(PreviewData.tags) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Leading Corner Case 1") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .topLeading, spacing: 7) {
            ForEach(PreviewData.cornerCase1) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Leading Corner Case 2") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(spacing: 7) {
            ForEach(PreviewData.cornerCase2) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Leading Random sizes") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(spacing: 7) {
            ForEach(0..<20) { _ in
                Color.rainbow.random()
                    .frame(width: .random(in: 40...200).rounded(),
                           height: .random(in: 30...90).rounded())
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Trailing Shuffled") {
    // MARK: - Trailing
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .topTrailing, spacing: 7) {
            ForEach(PreviewData.tags) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Trailing Corner Case 1") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .topTrailing, spacing: 7) {
            ForEach(PreviewData.cornerCase1) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Trailing Corner Case 2") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .topTrailing, spacing: 7) {
            ForEach(PreviewData.cornerCase2) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Trailing Random sizes") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .topTrailing, spacing: 7) {
            ForEach(0..<20) { _ in
                Color.rainbow.random()
                    .frame(width: .random(in: 40...200).rounded(),
                           height: .random(in: 30...90).rounded())
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Bottom Trailing Shuffled") {
    // MARK: - Bottom alignment
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .bottomTrailing, spacing: 7) {
            ForEach(PreviewData.tags) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Bottom Trailing Corner Case 1") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .bottomTrailing, spacing: 7) {
            ForEach(PreviewData.cornerCase1) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Bottom Trailing Corner Case 2") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .bottomTrailing, spacing: 7) {
            ForEach(PreviewData.cornerCase2) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Bottom Trailing Random sizes") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .bottomTrailing, spacing: 7) {
            ForEach(0..<20) { _ in
                Color.rainbow.random()
                    .frame(width: .random(in: 40...200).rounded(),
                           height: .random(in: 30...90).rounded())
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Center Shuffled") {
    // MARK: - Center alignment
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .center, spacing: 7) {
            ForEach(PreviewData.tags) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Center Random sizes") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .center, spacing: 7) {
            ForEach(0..<20) { _ in
                Color.rainbow.random()
                    .frame(width: .random(in: 40...200).rounded(),
                           height: .random(in: 30...90).rounded())
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Distribute Shuffled") {
    // MARK: - Distribute alignment
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .centerDistribute, spacing: 7) {
            ForEach(PreviewData.tags) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Distribute Random sizes") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .centerDistribute, spacing: 7) {
            ForEach(0..<20) { _ in
                Color.rainbow.random()
                    .frame(width: .random(in: 40...200).rounded(),
                           height: .random(in: 30...90).rounded())
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Justify Shuffled") {
    // MARK: - Justify alignment
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .centerJustify, spacing: 7) {
            ForEach(PreviewData.tags) { tag in
                TagView(tag: tag)
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}

#Preview("Justify Random sizes") {
    VStack(alignment: .leading, spacing: 0) {
        Color.clear //This makes the previews align to the leading edge
            .frame(maxHeight: 0)
        Flow(alignment: .centerJustify, spacing: 7) {
            ForEach(0..<20) { _ in
                Color.rainbow.random()
                    .frame(width: .random(in: 40...200).rounded(),
                           height: .random(in: 30...90).rounded())
                    .border(.teal, width: 4)
            }
        }
        .border(.red)
    }
}
#endif
