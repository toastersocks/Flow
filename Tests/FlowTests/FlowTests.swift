import XCTest
@testable import Flow
import struct SwiftUI.ProposedViewSize
import SwiftCheck


final class FlowTests: XCTestCase {
    func testSizeThatFitsMatchesGetRectsBoundingBox() throws {
        property("The rect returned from sizeThatFits should be equal to the union of all rects returned from getRects(for: in:)") <- forAll { (subviewSizes: [CGSize]) in
            let flow = Flow(alignment: .topLeading, spacing: 7)

            let sizeThatFits = flow.sizeThatFits(proposal: ProposedViewSize(width: 410, height: 1000), subviewSizes: subviewSizes)
            let placedSizes = flow.getRects(for: subviewSizes, in: CGRect(origin: .zero, size: sizeThatFits))
            let placedSizesBoundingBox = placedSizes.reduce(placedSizes.first ?? .zero) { $0.union($1) }

            return CGRect(origin: .zero, size: sizeThatFits).isNearlyEqual(to: placedSizesBoundingBox)
        }
    }
}
