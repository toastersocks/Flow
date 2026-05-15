import Testing
@testable import Flow
import Foundation
import struct SwiftUI.ProposedViewSize
import Exhaust

@Suite
final class FlowTests {
    @Test
    func `testSizeThat Fits Matches GetRects Bounding Box`() throws {
        let sizeGenerator = #gen(.cgfloat(in: 0.0 ... 410.0), .cgfloat(in: 0.0 ... 1000.0)) {
            CGSize(width: $0, height: $1)
        }
        let testCaseGenerator = #gen(
            sizeGenerator.array(length: 0 ... 100),
            .element(from: Flow.Alignment.allCases),
            #gen(.cgfloat(in: 0.0 ... 9_999.999)).optional(someWeight: 3, noneWeight: 2)
        )

        #exhaust(testCaseGenerator, .budget(.extensive)) { testCase in
            let (subviewSizes, alignment, spacing) = testCase
            let flow = Flow(alignment: alignment, spacing: spacing)

            let subviews = subviewSizes.map { MockLayoutSubview(spacing: MockViewSpacing(horizontalSpacing: 7, verticalSpacing: 5), priority: 0, width: $0.width, height: $0.height) }

            let sizeThatFits = flow.sizeThatFits(proposal: ProposedViewSize(width: 393, height: 1000), subviews: subviews)
            let placedSizes = flow.getRects(for: subviews, in: CGRect(origin: .zero, size: sizeThatFits))
            let placedSizesBoundingBox = placedSizes.reduce(CGRect.null) { $0.union($1) }

            #expect(sizeThatFits.isNearlyEqual(to: placedSizesBoundingBox.size))
        }
    }
}
