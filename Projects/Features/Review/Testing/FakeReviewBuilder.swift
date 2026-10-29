import ReviewInterface
import SwiftUI

/// 리뷰 화면 대신 이름만 보여 준다 (다른 Feature의 Example·테스트용).
public struct FakeReviewBuilder: ReviewBuilding {
    public init() {}

    public func make(_ route: ReviewRoute) -> AnyView {
        return AnyView(Text("Review: \(String(describing: route))"))
    }
}
