import SwiftUI


public struct Flow: Layout {
    let alignment: Alignment
    let spacing: CGFloat

    public init(alignment: Alignment = .topLeading, spacing: CGFloat) {
        self.alignment = alignment
        self.spacing = spacing
    }

    /// This internal method takes a proposed view size and an array of `CGSize` and returns a `CGSize` representing the bounding box that contains all the placed views,  using the flow's alignment and spacing. `Flow`'s implementation of `sizeThatFits(proposal: subviews: cache:)` calls this method internally to calculate the returned bounds. This is broken out to allow for testing.
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

            if currentPoint.x + currentViewSize.width > boundsWidth {
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


    /// This internal method takes a bounds rect and an array of `CGSize` and returns an array of `CGRect` representing the placed sizes using the flow's alignment and spacing within the bounds rect. `Flow`'s implementation of `placeSubview(in: proposal: subviews: cache:)` calls this method internally to calculate view placement. This is broken out to allow for testing.
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

        for (subviewIndex, viewSize) in sizes.enumerated() {
            let currentViewSize = viewSize
            let currentRowWidth = rowSubviews.map { $0.width }.reduce(0, +) + spacing * CGFloat(rowSubviews.count - 1)
            let currentRowHeight = rowSubviews.map { $0.height }.max() ?? 0
            let wouldOverflow = currentPoint.x + currentRowWidth + currentViewSize.width - 0.00000000001 > bounds.maxX
            let isLast = subviewIndex == sizes.indices.last

            if wouldOverflow || isLast {
                let totalRowWidth = currentRowWidth + (wouldOverflow ? 0 : currentViewSize.width + spacing)
                let totalRowHeight = max(currentRowHeight, wouldOverflow ? 0 : currentViewSize.height)

                if !wouldOverflow {
                    rowSubviews.append(viewSize)
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
                }
                for rowSubview in rowSubviews {
                    place(size: rowSubview, at: currentPoint, anchor: subviewAnchor)
                    currentPoint.x += rowSubview.width + spacing
                }
                currentPoint.x = bounds.minX
                currentPoint.y += (subviewAnchor == .topLeading ? totalRowHeight : 0) + spacing
                rowSubviews = [viewSize]

                if isLast && wouldOverflow {
                    switch alignment {
                    case .bottomLeading:
                        currentPoint.y += viewSize.height
                        fallthrough
                    case .topLeading:
                        currentPoint.x = bounds.minX
                    case .bottomTrailing:
                        currentPoint.y += viewSize.height
                        fallthrough
                    case .topTrailing:
                        let unusedSpace = bounds.maxX - viewSize.width
                        currentPoint.x = bounds.minX + unusedSpace
                    }
                    place(size: viewSize, at: currentPoint, anchor: subviewAnchor)
                }
            } else {
                rowSubviews.append(viewSize)
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

    public enum Alignment: CaseIterable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
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

        // MARK: - Wrong frame size returned by sizeThatFits corner case 1
        VStack(alignment: .leading, spacing: 0) {
            Color.clear //This makes the previews align to the leading edge
                .frame(maxHeight: 0)
            Flow(spacing: 7) {
                ForEach(PreviewData.cornerCase1) { tag in
                    TagView(tag: tag)
                        .border(.teal, width: 4)
                }
            }
            .border(.red)
            .frame(width: 410) // Important for the corner case to show up.
        }
        .previewDisplayName("Leading Corner Case 1")

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
        // MARK: - Wrong frame size returned by sizeThatFits corner case 1
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
            .frame(width: 410) // Important for the corner case to show up.
        }
        .previewDisplayName("Trailing Corner Case 1")
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
            // MARK: - Wrong frame size returned by sizeThatFits corner case 1
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
                .frame(width: 410) // Important for the corner case to show up.
            }
            .previewDisplayName("Bottom Trailing Corner Case 1")
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
    }
}
