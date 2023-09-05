import SwiftUI



/// A Flow layout arranges its subviews in a line, wrapping at the edge and starting new lines as needed, similar to how words wrap in a paragraph.
public struct Flow: Layout {
    let alignment: Alignment
    let spacing: CGFloat


    /// Creates an instance with the given alignment and spacing.
    /// - Parameters:
    ///   - alignment: The alignment guide for aligning the subviews in the flow.
    ///   - spacing: The distance between subviews. This spacing is not applied before the first, or after the last view in a row.
    public init(alignment: Alignment = .topLeading, spacing: CGFloat) {
        self.alignment = alignment
        self.spacing = spacing
    }

    /// Computes the overall size required to fit an array of subview sizes, based on a proposed view size.
    /// - Parameters:
    ///   - proposal: The proposed size offered to place views.
    ///   - subviewSizes: An array of sizes for which to calculate the bounding box.
    /// - Returns: A `CGSize` representing the bounding box containing the placed sizes.
    func sizeThatFits(proposal: ProposedViewSize, subviewSizes: [CGSize]) -> CGSize {
        let totalChildWidthWithSpacing = subviewSizes.map(\.width).reduce(0, +) + (spacing * CGFloat(subviewSizes.count - 1))

        let minimumParentWidth = subviewSizes.map(\.width).max() ?? 0

        let boundsWidth = max(proposal.width ?? totalChildWidthWithSpacing, minimumParentWidth)

        var currentPoint = CGPoint(x: 0, y: 0)
        var currentRowMaxHeight: CGFloat = 0

        var maxX: CGFloat = 0
        var maxY: CGFloat = 0

        for currentViewSize in subviewSizes {
            if currentPoint.x > 0 {
                currentPoint.x += spacing
            }

            let rowBoundsDifference = currentPoint.x + currentViewSize.width - boundsWidth
            let wouldOverflow = rowBoundsDifference > 0.000_000_000_001

            if wouldOverflow {
                currentPoint.x = 0
                currentPoint.y += spacing + currentRowMaxHeight
                currentRowMaxHeight = 0
            }

            currentRowMaxHeight = max(currentRowMaxHeight, currentViewSize.height)

            currentPoint.x += currentViewSize.width

            maxX = max(maxX, currentPoint.x)
            maxY = max(maxY, currentPoint.y + currentViewSize.height)
        }

        return CGSize(width: maxX, height: maxY)
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        sizeThatFits(proposal: proposal, subviewSizes: subviews.map { $0.sizeThatFits(.unspecified) })
    }


    /// Determines the layout rectangles for a set of sizes within the given bounds, based on the flow's alignment and spacing.
    /// - Parameters:
    ///   - bounds: The bounds in which to place the sizes.
    ///   - sizes: An array of sizes for which to calculate placement.
    /// - Returns: An array of `CGRect` representing the placed sizes. The origins of the rects are normalized to the top-left of the rects. The bounding box encompassing the full extents of the rects can be found by performing a union of all the rects.
    func getRects(for sizes: [CGSize], in bounds: CGRect) -> [CGRect] {
        var viewRects: [CGRect] = []

        func place(size: CGSize, at point: CGPoint, anchor: UnitPoint) {
            let topLeft = CGPoint(x: point.x - size.width * anchor.x, y: point.y - size.height * anchor.y)
            let normalizedRect = CGRect(origin: topLeft, size: size)

            viewRects.append(normalizedRect)
        }

        var currentPoint = CGPoint(x: bounds.minX, y: bounds.minY)
        var rowSubviews: [CGSize] = []

        for (subviewIndex, currentViewSize) in sizes.enumerated() {
            let currentRowWidth = rowSubviews.map { $0.width }.reduce(0, +) + spacing * CGFloat(rowSubviews.count - 1)
            let currentRowHeight = rowSubviews.map { $0.height }.max() ?? 0
            let rowBoundsDifference = currentPoint.x + currentRowWidth + spacing + currentViewSize.width - bounds.maxX

            let wouldOverflow = rowBoundsDifference > 0.000_000_000_001
            let isLast = subviewIndex == sizes.indices.last

            if wouldOverflow || isLast {
                let totalRowWidth = currentRowWidth + (wouldOverflow ? 0 : currentViewSize.width + spacing)
                let totalRowHeight = max(currentRowHeight, wouldOverflow ? 0 : currentViewSize.height)

                if !wouldOverflow {
                    rowSubviews.append(currentViewSize)
                }

                let unusedHorizontalSpace = bounds.maxX - totalRowWidth
                var subviewAnchor: UnitPoint = .topLeading
                switch alignment {
                case .bottomLeading:
                    currentPoint.y += totalRowHeight
                    subviewAnchor = .bottomLeading
                    fallthrough
                case .topLeading:
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
                    if unusedHorizontalSpace > spacing * 2 {
                        let distributedUnusedHorizontalSpace = (unusedHorizontalSpace - spacing * 2) / CGFloat(rowSubviews.count + 1)
                        currentPoint.x += distributedUnusedHorizontalSpace + spacing
                    } else {
                        currentPoint.x = bounds.minX + min(unusedHorizontalSpace * 0.5, spacing)
                    }

                }
                for rowSubview in rowSubviews {
                    if alignment == .center || alignment == .centerDistribute {
                        currentPoint.y += (totalRowHeight - rowSubview.height) * 0.5
                    }

                    place(size: rowSubview, at: currentPoint, anchor: subviewAnchor)

                    if alignment == .center || alignment == .centerDistribute  {
                        currentPoint.y -= (totalRowHeight - rowSubview.height) * 0.5
                    }

                    let horizontalSpacing: CGFloat
                    if alignment == .centerDistribute && unusedHorizontalSpace > spacing * 2 {
                        let distributedUnusedHorizontalSpace = (unusedHorizontalSpace - spacing * 2) / CGFloat(rowSubviews.count + 1)
                        horizontalSpacing = distributedUnusedHorizontalSpace + spacing
                    } else {
                        horizontalSpacing = spacing
                    }

                    currentPoint.x += rowSubview.width + horizontalSpacing
                }
                currentPoint.x = bounds.minX
                currentPoint.y += (subviewAnchor == .topLeading ? totalRowHeight : 0) + spacing
                rowSubviews = [currentViewSize]

                if isLast && wouldOverflow {
                    switch alignment {
                    case .bottomLeading:
                        currentPoint.y += currentViewSize.height
                        fallthrough
                    case .topLeading:
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
                    place(size: currentViewSize, at: currentPoint, anchor: subviewAnchor)
                }
            } else {
                rowSubviews.append(currentViewSize)
            }
        }

        return viewRects
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let viewRects = getRects(for: subviews.map { $0.sizeThatFits(.unspecified) },
                              in: bounds)

        for (subview, rect) in zip(subviews, viewRects) {
            subview.place(at: rect.origin, anchor: .topLeading, proposal: .unspecified)
        }
    }


    /// The alignment of subviews within the flow.
    public enum Alignment: CaseIterable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
        case center
        case centerDistribute
    }
}

struct Flow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
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
        .previewDisplayName("Leading Shuffled")

        // MARK: - Wrong frame size returned by sizeThatFits corner case 2
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
        .previewDisplayName("Leading Corner Case 2")

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
        .previewDisplayName("Leading Random sizes")
    }
        Group {
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
        .previewDisplayName("Trailing Shuffled")

        // MARK: - Wrong frame size returned by sizeThatFits corner case 2
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
        .previewDisplayName("Trailing Corner Case 2")

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
        .previewDisplayName("Trailing Random sizes")
    }
        Group {
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
            .previewDisplayName("Bottom Trailing Shuffled")

            // MARK: - Wrong frame size returned by sizeThatFits corner case 2
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
            .previewDisplayName("Bottom Trailing Corner Case 2")

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
            .previewDisplayName("Bottom Trailing Random sizes")
        }
        Group {
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
            .previewDisplayName("Center Shuffled")

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
            .previewDisplayName("Center Random sizes")
        }

        Group {
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
            .previewDisplayName("Distribute Shuffled")

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
            .previewDisplayName("Distribute Random sizes")
        }
    }
}
