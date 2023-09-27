import XCTest
@testable import Flow
import struct SwiftUI.ProposedViewSize
import SwiftCheck


final class FlowTests: XCTestCase {
    func testSizeThatFitsMatchesGetRectsBoundingBox() throws {
        let checkerArguments = CheckerArguments(maxAllowableSuccessfulTests: 1_000)
        let spacingGenerator = Gen<CGFloat?>.frequency(
            [(2, Gen<CGFloat?>.pure(nil)),
             (3, CGFloat.arbitrary.suchThat { $0 >= 0 && $0 < 10_000 }.map(Optional.some))]
        )
        property("The rect returned from sizeThatFits should be equal to the union of all rects returned from getRects(for: in:)", arguments: checkerArguments) <- forAll(
            CGSize.arbitrary.proliferate,
            Flow.Alignment.arbitrary,
            spacingGenerator
        ) { (subviewSizes: [CGSize], alignment: Flow.Alignment, spacing: CGFloat?) in
            let flow = Flow(alignment: alignment, spacing: spacing)

            let subviews = subviewSizes.map { MockLayoutSubview(spacing: MockViewSpacing(horizontalSpacing: 7, verticalSpacing: 5), priority: 0, width: $0.width, height: $0.height) }

            let sizeThatFits = flow.sizeThatFits(proposal: ProposedViewSize(width: 393, height: 1000), subviews: subviews)
            let placedSizes = flow.getRects(for: subviews, in: CGRect(origin: .zero, size: sizeThatFits))
            let placedSizesBoundingBox = placedSizes.reduce(placedSizes.first ?? .zero) { $0.union($1) }

            return sizeThatFits.isNearlyEqual(to: placedSizesBoundingBox.size)
        }
    }
}
