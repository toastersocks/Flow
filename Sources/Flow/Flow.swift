import SwiftUI


public struct Flow: Layout {
    let spacing: CGFloat


    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let idealChildSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let totalChildWidthWithSpacing = idealChildSizes.map(\.width).reduce(0, +) + (spacing * CGFloat(subviews.count - 1))

        let minimumParentWidth = idealChildSizes.map(\.width).max() ?? 0

        let boundsWidth = max(proposal.width ?? totalChildWidthWithSpacing, minimumParentWidth)

        var currentPoint = CGPoint(x: 0, y: 0)
        var currentRowMaxHeight: CGFloat = 0

        var maxX: CGFloat = 0
        var maxY: CGFloat = 0

        for view in subviews {
            let currentViewSize = view.sizeThatFits(.unspecified)
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

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentPoint = CGPoint(x: bounds.minX, y: bounds.minY)
        var currentRowMaxHeight: CGFloat = 0
        for view in subviews {
            let currentViewSize = view.sizeThatFits(.unspecified)
            if currentPoint.x > bounds.minX {
                currentPoint.x += spacing
            }
            if currentPoint.x + currentViewSize.width - 0.00000000001 > bounds.maxX {
                currentPoint.x = bounds.minX
                currentPoint.y += currentRowMaxHeight + spacing
                currentRowMaxHeight = 0
            }

            view.place(at: currentPoint, anchor: .topLeading, proposal: .unspecified)
            currentRowMaxHeight = max(currentRowMaxHeight, currentViewSize.height)

            currentPoint.x += currentViewSize.width
        }
    }
}

struct Flow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear //This makes the previews align to the leading edge
                .frame(maxHeight: 0)
            Flow(spacing: 7) {
                ForEach(PreviewData.tags) { tag in
                    TagView(tag: tag)
                }
            }
            .border(.red)
        }
        .previewDisplayName("Shuffled")
        // MARK: - Wrong frame size returned by sizeThatFits corner case 1
        VStack(alignment: .leading, spacing: 0) {
            Color.clear //This makes the previews align to the leading edge
                .frame(maxHeight: 0)
            Flow(spacing: 7) {
                ForEach(PreviewData.cornerCase1) { tag in
                    TagView(tag: tag)
                }
            }
            .border(.red)
            .frame(width: 410) // Important for the corner case to show up.
        }
        .previewDisplayName("Corner Case 1")
        // MARK: - Wrong frame size returned by sizeThatFits corner case 2
        VStack(alignment: .leading, spacing: 0) {
            Color.clear //This makes the previews align to the leading edge
                .frame(maxHeight: 0)
            Flow(spacing: 7) {
                ForEach(PreviewData.cornerCase2) { tag in
                    TagView(tag: tag)
                }
            }
            .border(.red)
        }
        .previewDisplayName("Corner Case 2")

        VStack(alignment: .leading, spacing: 0) {
            Color.clear //This makes the previews align to the leading edge
                .frame(maxHeight: 0)
            Flow(spacing: 7) {
                ForEach(0..<20) { _ in
                    Color.rainbow.random()
                        .frame(width: .random(in: 40...200).rounded(),
                               height: .random(in: 30...90).rounded())
                }
            }
            .border(.red)
        }
        .previewDisplayName("Random sizes")
    }
}
