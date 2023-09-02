import XCTest
import struct SwiftUI.ProposedViewSize
@testable import Flow


final class FlowTests: XCTestCase {
    func testSizeThatFitsMatchesGetRectsBoundingBox() throws {
        let flow = Flow(alignment: .topLeading, spacing: 7)
        let subviewSizes = (0..<20).map { _ in CGSize(width: Int.random(in: 40...200), height: Int.random(in: 30...90)) }

        let sizeThatFits = flow.sizeThatFits(proposal: ProposedViewSize(width: 410, height: 1000), subviewSizes: subviewSizes)

        let placedSizes = flow.getRects(for: subviewSizes, in: CGRect(origin: .zero, size: sizeThatFits))

        let placedSizesBoundingBox = placedSizes.reduce(placedSizes[0]) { $0.union($1)
        }

        XCTAssertEqual(sizeThatFits, placedSizesBoundingBox.size)
    }
}
