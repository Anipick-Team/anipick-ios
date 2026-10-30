import SwiftUI

/// 끌어서 0.5 단위로 고르는 별 5개와 "(4.5)" 표시. 레거시 `StarRatingComponentView`와 같은 모양·동작이다.
///
/// 레거시처럼 처음 값만 받아 안에서 보관하고, 바뀔 때마다 `onChange`로 알린다.
public struct StarRatingInput: View {
    @State private var rating: Double
    private let fontSize: CGFloat
    private let fontColor: Color
    private let starSize: CGFloat
    private let onChange: (Double) -> Void

    private let starCount = 5

    public init(
        rating: Double,
        fontSize: CGFloat,
        fontColor: Color,
        starSize: CGFloat,
        onChange: @escaping (Double) -> Void
    ) {
        _rating = State(initialValue: rating)
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.starSize = starSize
        self.onChange = onChange
    }

    public var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(1...starCount, id: \.self) { index in
                        star(at: index)
                            .resizable()
                            .frame(width: starSize, height: starSize)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            rating = Self.rating(at: value.location.x, starSize: starSize)
                            onChange(rating)
                        }
                )
            }

            Text("(\(rating, specifier: "%.1f"))")
                .textStyle(size: fontSize, color: fontColor)
                .padding(.leading, 8)
                .lineLimit(1)
                .fixedSize()
        }
    }

    private func star(at index: Int) -> Image {
        if rating >= Double(index) {
            return Image(.fillPickStar)
        } else if rating >= Double(index) - 0.5 {
            return Image(.halfStar)
        } else {
            return Image(.unfillStar)
        }
    }

    /// 끈 위치의 별점. 0~5로 자르고 0.5 단위로 반올림한다 (가운데 값은 짝수 쪽, 레거시와 같음)
    nonisolated static func rating(at x: CGFloat, starSize: CGFloat) -> Double {
        let totalWidth = starSize * 5
        let clamped = min(max(0, x), totalWidth)
        let raw = Double(clamped / starSize)
        return (raw * 2).rounded(.toNearestOrEven) / 2
    }
}
