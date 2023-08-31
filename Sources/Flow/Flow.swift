import SwiftUI


public struct Flow<Content>: Layout {
    let spacing: CGFloat


    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let idealChildSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let totalChildWidthWithSpacing = idealChildSizes.map(\.width).reduce(0, +) + (spacing * CGFloat(subviews.count - 1))

        let minimumParentWidth = idealChildSizes.map(\.width).max() ?? 0

        let boundsWidth = max(proposal.width ?? totalChildWidthWithSpacing, minimumParentWidth)

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        print("bounds: \(bounds), proposal: \(proposal)")
        var currentPoint = CGPoint(x: bounds.minX, y: bounds.minY)
        var currentRowMaxHeight: CGFloat = 0

        for view in subviews {
            let currentViewSize = view.sizeThatFits(.unspecified)
            if currentPoint.x > 0 {
                currentPoint.x += spacing
            }

            if currentPoint.x + currentViewSize.width > boundsWidth {
                currentPoint.x = 0
                currentPoint.y += currentRowMaxHeight + spacing
            }

            currentRowMaxHeight = max(currentRowMaxHeight, currentViewSize.height)

            currentPoint.x += currentViewSize.width

            maxX = max(maxX, currentPoint.x)
            maxY = max(maxY, currentPoint.y + currentViewSize.height)
        }

        return CGSize(width: maxX, height: maxY)
    }

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
