import SwiftUI


public struct Flow<Content>: Layout {
    let spacing: CGFloat


    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let idealChildSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let totalChildWidthWithSpacing = idealChildSizes.map(\.width).reduce(0, +) + (spacing * CGFloat(subviews.count - 1))

        let minimumParentWidth = idealChildSizes.map(\.width).max() ?? 0

        let offeredWidth = max(proposal.width ?? totalChildWidthWithSpacing, minimumParentWidth) // Space offered to parent

        var maxRowWidth: CGFloat = 0 // longest row
        var maxRowHeights: [CGFloat] = [] // tallest height in each row
        var currentRowSizes: [CGSize] = []

        for (index, view) in subviews.enumerated() {
            let currentViewSize = view.sizeThatFits(.unspecified)
            let potentialRow = currentRowSizes + [currentViewSize]
            let potentialRowWidth = potentialRow.map(\.width).reduce(0, +) + spacing * CGFloat(potentialRow.count - 1)

            if potentialRowWidth <= offeredWidth {
                currentRowSizes = potentialRow
                maxRowWidth = max(maxRowWidth, potentialRowWidth)
            }

            if potentialRowWidth > offeredWidth || index == subviews.endIndex - 1 {
                if let maxRowHeight = currentRowSizes.map(\.height).max() {
                    maxRowHeights.append(maxRowHeight)
                }
                currentRowSizes = [currentViewSize]
            }
        }
        let totalHeight: CGFloat = maxRowHeights.reduce(0, +) + spacing * CGFloat(maxRowHeights.count - 1)
        let parentSize = CGSize(width: maxRowWidth, height: totalHeight)
        print("Returning size of: \(parentSize)")

        return parentSize
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        print("bounds: \(bounds), proposal: \(proposal)")
        var currentPoint = CGPoint(x: bounds.minX, y: bounds.minY)
        var currentRowMaxHeight: CGFloat = 0

        for view in subviews {
            let currentViewSize = view.sizeThatFits(.unspecified)
            if currentPoint.x > bounds.minX && currentPoint.x + currentViewSize.width <= bounds.maxX {
                currentPoint.x += spacing
            }

            if currentPoint.x + currentViewSize.width > bounds.maxX {
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
        Flow<Any>(spacing: 7) {
            ForEach(PreviewData.tags) { tag in
                TagView(tag: tag)
            }
        }
    }
}
