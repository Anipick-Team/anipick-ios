import DesignSystem
import MyInfoClientInterface
import SwiftUI

/// 레거시 `MyReviewCell`과 같은 모양.
///
/// 레거시 그대로: 별점을 끌어도 표시는 바뀌지 않고, 좋아요 버튼은 아무 일도 하지 않는다(둘 다 칸 탭이 상세로 가는 것만 막는다).
/// "더보기" 판단은 14pt로 재고 본문은 16pt로 보여 준다.
struct RatedReviewCell: View {
    let review: RatedReview
    let onMoreTapped: (CGRect) -> Void
    let onTapped: () -> Void

    @State private var contentLineLimit: Int? = 2
    @State private var collapsedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                if let url = review.coverImageUrl {
                    // 표지 비율을 따라 너비가 정해지므로 RemoteImage(받은 크기를 채움) 대신 AsyncImage를 쓴다
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .success(let image):
                            cover(image)
                        case .empty, .failure:
                            cover(Image(.animeThumbnail))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                Text(review.title ?? "--")
                    .textStyle(size: 16, color: .anipickBlack)
                    .padding(.leading, 16)

                Spacer()
            }

            Rectangle()
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.gray7)
                .padding(.vertical, 19)

            HStack(alignment: .center, spacing: 0) {
                stars(review.rating ?? 0)
                Spacer()
            }
            .padding(.bottom, 8)

            Text(review.createdAt ?? "--")
                .foregroundStyle(.gray6)
                .font(.system(size: 12))

            Spacer().frame(height: 16)

            if let content = review.reviewContent {
                Text(content)
                    .lineLimit(contentLineLimit)
                    .font(.system(size: 16))
                    .foregroundStyle(.anipickBlack)
                    .padding(.bottom, 4)
                    .overlay(heightProbes(content))
            }
            if fullHeight > collapsedHeight + 1 {
                moreButton()
            }
            Spacer().frame(height: 20)

            HStack(alignment: .center, spacing: 0) {
                Button {
                } label: {
                    Image(.unfilledHeart)
                        .padding(.trailing, 4)
                }

                if let likeCount = review.likeCount {
                    Text("\(likeCount)")
                        .foregroundStyle(.gray6)
                        .font(.system(size: 14))
                }

                Spacer()

                GeometryReader { proxy in
                    Button {
                        onMoreTapped(proxy.frame(in: .global))
                    } label: {
                        Image(.moreVerticalGray)
                    }
                    .frame(width: 20, height: 20)
                }
                .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
    }

    private func cover(_ image: Image) -> some View {
        return
            image
            .resizable()
            .scaledToFit()
            .frame(height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// 3줄 높이와 전체 높이를 잰다 (보이지 않음)
    private func heightProbes(_ content: String) -> some View {
        return VStack {
            Text(content)
                .textStyle(size: 14, color: .anipickBlack)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    collapsedHeight = $0
                }
                .hidden()

            Text(content)
                .textStyle(size: 14, color: .anipickBlack)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    fullHeight = $0
                }
                .hidden()
        }
    }

    private func moreButton() -> some View {
        return HStack(alignment: .center, spacing: 0) {
            Button {
                contentLineLimit = contentLineLimit == 3 ? nil : 3
            } label: {
                HStack(alignment: .center, spacing: 0) {
                    Text("더보기")
                        .font(.system(size: 14))
                        .foregroundStyle(.anipickPrimary)
                        .padding(.trailing, 4)

                    Image(.chevronDownPrimary)
                        .rotationEffect(contentLineLimit == 3 ? .degrees(0) : .degrees(180))
                }
            }

            Spacer()
        }
    }

    private func stars(_ rating: Double) -> some View {
        return HStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { index in
                    star(rating, index)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
            .gesture(DragGesture(minimumDistance: 0).onChanged { _ in })

            Text("\(rating, specifier: "%.1f")")
                .padding(.leading, 8)
                .textStyle(size: 14, color: .gray8)
        }
    }

    private func star(_ rating: Double, _ index: Int) -> Image {
        if rating >= Double(index) {
            return Image(.fillPickStar)
        } else if rating >= Double(index) - 0.5 {
            return Image(.halfStar)
        } else {
            return Image(.unfillStar)
        }
    }
}
