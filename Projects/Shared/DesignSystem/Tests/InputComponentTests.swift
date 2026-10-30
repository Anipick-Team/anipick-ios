import Testing

@testable import DesignSystem

@Suite("입력 컴포넌트")
struct InputComponentTests {
    @Test(
        "V2. 별점은 끈 위치를 0~5로 자르고 0.5 단위로 반올림한다 (가운데는 짝수 쪽)",
        arguments: [
            (-10.0, 0.0), (0.0, 0.0), (8.0, 0.0), (16.0, 0.5), (24.0, 1.0), (40.0, 1.0),
            (48.0, 1.5), (80.0, 2.5), (160.0, 5.0), (400.0, 5.0),
        ]
    )
    func ratingAtPosition(x: Double, expected: Double) {
        #expect(StarRatingInput.rating(at: x, starSize: 32) == expected)
    }

    @Test(
        "V5. 200자를 넘기면 앞 200자만 남긴다 (경계: 200자는 그대로, 201자부터 자름)",
        arguments: [200, 201, 205]
    )
    func truncatesText(count: Int) {
        let text = String(repeating: "가", count: count)

        #expect(LimitedTextEditor.truncated(text, limit: 200) == String(repeating: "가", count: 200))
    }
}
