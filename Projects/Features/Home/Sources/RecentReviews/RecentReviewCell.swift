import DesignSystem
import ReviewClientInterface
import SwiftUI

/// 레거시 `RecentReviewCellInHome`과 같은 모양.
///
/// 레거시 그대로: 별점을 끌어도 표시는 바뀌지 않는다. "더보기" 판단은 14pt로 재고 본문은 16pt로 보여 준다.
/// 프로필은 받기 전·실패하면 초록 원이다.
struct RecentReviewCell: View {
    let review: RecentReview
    let profileImageURL: URL?
    let onLikeTapped: () -> Void
    let onMoreTapped: (CGRect) -> Void
    @State private var contentLineLimit: Int? = 2
    @State private var collapsedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                if let url = review.animeCoverImageUrl {
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

                Text(review.animeTitle ?? "-")
                    .foregroundStyle(.anipickBlack)
                    .font(.system(size: 16))
                    .padding(.leading, 12)
            }

            HStack(spacing: 0) {
                stars(review.rating ?? 0.0)

                Spacer()

                ReviewerAvatar(url: profileImageURL)

                Text(review.nickname ?? "--")
                    .foregroundStyle(.anipickBlack)
                    .font(.system(size: 12))
                    .padding(.leading, 8)
            }

            Text(review.createdAt ?? "--")
                .foregroundStyle(.gray6)
                .font(.system(size: 12))

            Spacer().frame(height: 16)

            Text(review.text)
                .lineLimit(contentLineLimit)
                .font(.system(size: 16))
                .foregroundStyle(.anipickBlack)
                .padding(.bottom, 4)
                .overlay(heightProbes(review.text))

            if fullHeight > collapsedHeight + 1 {
                moreButton()
            }

            Spacer().frame(height: 20)

            HStack(alignment: .center, spacing: 0) {
                Button {
                    onLikeTapped()
                } label: {
                    Image(review.isLiked == true ? .fillHeartGreen : .unfilledHeart)
                        .resizable()
                        .frame(width: 16, height: 16)
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
    }

    private func cover(_ image: Image) -> some View {
        return
            image
            .resizable()
            .scaledToFit()
            .frame(height: 120)
            .cornerRadius(12)
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
            // 레거시는 끌면 칸 안의 별점 값만 바꾸고 표시에는 쓰지 않는다
            .gesture(DragGesture(minimumDistance: 0).onChanged { _ in })

            Text("\(rating, specifier: "%.1f")")
                .padding(.leading, 8)
                .textStyle(size: 13, color: .gray8)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
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

/// 리뷰 작성자 프로필 (인증 이미지). 받기 전·실패하면 초록 원 (레거시 그대로)
private struct ReviewerAvatar: View {
    let url: URL?
    @Environment(\.protectedImageLoader) private var loader
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            } else {
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.green)
                    .padding(.trailing, 8)
            }
        }
        .task(id: url) {
            guard let url else {
                return
            }
            image = try? await loader.image(
                for: url, maxPixelSize: Int((30 * displayScale).rounded(.up)))
        }
    }
}
