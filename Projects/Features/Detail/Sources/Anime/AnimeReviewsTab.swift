import DesignSystem
import ReviewClientInterface
import SwiftUI

/// "리뷰" 탭 (레거시 `ReviewDetailInfoView`). 메뉴·신고·차단 창은 상세 화면이 맨 위에 띄운다
struct AnimeReviewsTab: View {
    let state: AnimeDetailReducer.State
    let imageURL: (Int) -> URL
    let send: (AnimeDetailReducer.Intent) -> Void
    @State private var lineLimit: Int? = 3
    @State private var collapsedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                if state.myReviewContent.isEmpty {
                    ratingBox()
                } else {
                    myReviewCard()
                }

                Spacer().frame(height: 48)

                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 5)
                    .foregroundColor(.gray7)
                    .padding(.horizontal, -20)

                Spacer().frame(height: 28)

                HStack(alignment: .center, spacing: 0) {
                    Text("리뷰")
                        .textStyle(size: 24, color: .anipickBlack, weight: .bold)
                        .padding(.trailing, 8)

                    Text("\(state.reviewCount)개")
                        .textStyle(size: 14, color: .gray6)

                    Spacer()

                    Text("스포일러")
                        .textStyle(size: 16, color: .anipickSecondary, weight: .bold)

                    Button {
                        send(.spoilerToggled)
                    } label: {
                        Image(state.showsSpoilers ? .toggleEnable : .toggleDisable)
                    }
                }

                Spacer().frame(height: 32)

                reviewList()
            }

            if state.isSortMenuPresented {
                ReviewSortMenu { send(.sortSelected($0)) }
                    .padding(.top, 400)
                    .padding(.trailing, 0)
            }
        }
        .background(Color.white)
        .onAppear {
            send(.reviewTabAppeared)
        }
        .onDisappear {
            send(.reviewTabDisappeared)
        }
    }

    // MARK: - 내 별점·내 리뷰

    private func ratingBox() -> some View {
        return VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .frame(height: 123)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    .foregroundColor(.gray7)

                VStack(alignment: .center, spacing: 0) {
                    DraggableRating(
                        initialRating: state.storedRating, fontSize: 20, fontColor: .gray6,
                        starSize: 32
                    ) { send(.ratingDragged($0)) }
                }
            }
            .padding(.bottom, 12)

            Button {
                send(.writeDetailTapped)
            } label: {
                Text("상세 리뷰 작성하기")
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(state.pendingRating > 0 ? .anipickPrimary : Color.gray6)
            }
            .cornerRadius(8)
        }
    }

    private func myReviewCard() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Text("내 리뷰")
                .textStyle(size: 18, color: .anipickBlack, weight: .black)
                .padding(.bottom, 13)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    BoundRating(
                        rating: Binding(
                            get: { state.storedRating }, set: { send(.myRatingDragged($0)) }),
                        fontSize: 14, fontColor: .gray8, starSize: 20)

                    Spacer()

                    Text(state.myReviewCreatedAt)
                        .textStyle(size: 12, color: .gray6)
                }
                .padding(.bottom, 16)

                Text(state.myReviewContent)
                    .textStyle(size: 16, color: .anipickBlack, weight: .semibold)
                    .lineLimit(lineLimit)
                    .padding(.bottom, 16)
                    .overlay(heightProbes(state.myReviewContent))

                if fullHeight > collapsedHeight + 1 {
                    HStack(alignment: .center, spacing: 0) {
                        Button {
                            lineLimit = lineLimit == 3 ? nil : 3
                        } label: {
                            HStack(alignment: .center, spacing: 0) {
                                Text("더보기")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.anipickPrimary)
                                    .padding(.trailing, 4)

                                Image(.chevronDownPrimary)
                                    .rotationEffect(lineLimit == 3 ? .degrees(0) : .degrees(180))
                            }
                        }

                        Spacer()
                    }
                    .padding(.bottom, 4)
                }

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .resizable()
                            .frame(width: 14, height: 14)
                            .foregroundColor(.gray)

                        Text("\(state.myLikeCount)")
                            .textStyle(size: 14, color: .gray6)
                    }

                    Spacer()

                    GeometryReader { proxy in
                        Button {
                            send(.myReviewMoreTapped(anchorMaxY: proxy.frame(in: .global).maxY))
                        } label: {
                            Image(.moreVerticalGray)
                        }
                        .frame(width: 20, height: 20)
                    }
                    .frame(width: 20, height: 20)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1))
            )
        }
    }

    // MARK: - 리뷰 목록

    private func reviewList() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 32)

            HStack(alignment: .center, spacing: 0) {
                Spacer()

                Button {
                    send(.sortButtonTapped)
                } label: {
                    HStack(alignment: .center, spacing: 0) {
                        Text(state.reviewSort.rawValue)
                            .padding(.trailing, 4)

                        Image(systemName: state.isSortMenuPresented ? "chevron.up" : "chevron.down")
                            .resizable()
                            .frame(width: 9, height: 6)
                    }
                }
            }
            .textStyle(size: 14, color: .gray8)
            .foregroundColor(Color.gray8)
            .padding(.bottom, 13)
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            if state.reviews.count > 0 {
                ForEach(state.reviews, id: \.reviewId) { review in
                    VStack(spacing: 0) {
                        AnimeReviewCell(
                            review: review, profileImageURL: review.profileImageId.map(imageURL),
                            onLikeTapped: { send(.reviewLikeTapped(review, liked: $0)) },
                            onMoreTapped: { send(.reviewMoreTapped(review, anchorMaxY: $0)) }
                        )
                        .onAppear {
                            send(.reviewAppeared(review))
                        }
                        .padding(.bottom, 12)
                        .padding(.horizontal, 20)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    Image(.emptyReviewIcon)
                        .resizable()
                        .frame(width: 150)
                        .padding(.bottom, 30)

                    Text("아직 리뷰가 없어요!\n첫 번째 리뷰의 주인공이 되어볼까요?")
                        .textStyle(size: 14, color: .gray8)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            Spacer()
        }
        .background(Color.gray7)
        .padding(.horizontal, -20)
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
}

/// 리뷰 한 칸 (레거시 상세용 `RecentReviewCell`).
///
/// 레거시 그대로: 좋아요 표시는 칸이 들고 있다(처음 보일 때 서버 값으로 맞추고, 누르면 개수 + 0/1). 별점을 끌어도 표시는 바뀌지 않는다.
struct AnimeReviewCell: View {
    let review: RecentReview
    let profileImageURL: URL?
    let onLikeTapped: (Bool) -> Void
    let onMoreTapped: (Double) -> Void
    @State private var contentLineLimit: Int? = 2
    @State private var collapsedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0
    @State private var isLiked = false
    @State private var addedLike = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                stars(review.rating ?? 0.0)

                Spacer()

                ReviewerAvatar(url: profileImageURL)

                Text(review.nickname ?? "--")
                    .foregroundStyle(.anipickBlack)
                    .font(.system(size: 12))
                    .padding(.leading, 4)
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
                HStack(alignment: .center, spacing: 0) {
                    Button {
                        contentLineLimit = contentLineLimit == 2 ? nil : 2
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Text("더보기")
                                .font(.system(size: 14))
                                .foregroundStyle(.anipickPrimary)
                                .padding(.trailing, 4)

                            Image(.chevronDownPrimary)
                                .rotationEffect(contentLineLimit == 2 ? .degrees(0) : .degrees(180))
                        }
                    }

                    Spacer()
                }
            }

            Spacer().frame(height: 20)

            HStack(alignment: .center, spacing: 0) {
                Button {
                    isLiked.toggle()
                    onLikeTapped(isLiked)
                    addedLike = isLiked ? 1 : 0
                } label: {
                    Image(isLiked ? .fillHeartGreen : .unfilledHeart)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(.trailing, 4)
                }

                if let likeCount = review.likeCount {
                    Text("\(likeCount + addedLike)")
                        .foregroundStyle(.gray6)
                        .font(.system(size: 14))
                }

                Spacer()

                GeometryReader { proxy in
                    Button {
                        onMoreTapped(proxy.frame(in: .global).maxY)
                    } label: {
                        Image(.moreVerticalGray)
                            .frame(width: 20, height: 20)
                    }
                }
                .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(8)
        .onAppear {
            isLiked = review.isLiked ?? false
        }
    }

    private func stars(_ rating: Double) -> some View {
        return HStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { index in
                    starImage(rating, index)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
            // 레거시는 끌면 칸 안의 값만 바꾸고 표시에는 쓰지 않는다
            .gesture(DragGesture(minimumDistance: 0).onChanged { _ in })

            Text("\(rating, specifier: "%.1f")")
                .padding(.leading, 8)
                .textStyle(size: 13, color: .gray8)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
        }
    }

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
}

/// 별 5개 (반 개 단위). 레거시 리뷰 화면들과 같은 이미지
func starImage(_ rating: Double, _ index: Int) -> Image {
    if rating >= Double(index) {
        return Image(.fillPickStar)
    } else if rating >= Double(index) - 0.5 {
        return Image(.halfStar)
    } else {
        return Image(.unfillStar)
    }
}

/// 끌어서 고르는 별점 (레거시 `StarRatingComponentView`). 처음 값만 받고 이후는 스스로 들고 있다. 끌 때마다 알린다
struct DraggableRating: View {
    @State private var rating: Double
    let fontSize: CGFloat
    let fontColor: Color
    let starSize: CGFloat
    let onChange: (Double) -> Void

    init(
        initialRating: Double, fontSize: CGFloat, fontColor: Color, starSize: CGFloat,
        onChange: @escaping (Double) -> Void
    ) {
        _rating = State(initialValue: initialRating)
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.starSize = starSize
        self.onChange = onChange
    }

    var body: some View {
        RatingRow(rating: rating, fontSize: fontSize, fontColor: fontColor, starSize: starSize) {
            value in
            rating = value
            onChange(value)
        }
    }
}

/// 바깥 값에 묶인 별점 (레거시 `StarRatingComponentView2`)
struct BoundRating: View {
    @Binding var rating: Double
    let fontSize: CGFloat
    let fontColor: Color
    let starSize: CGFloat

    var body: some View {
        RatingRow(rating: rating, fontSize: fontSize, fontColor: fontColor, starSize: starSize) {
            value in
            rating = value
        }
    }
}

/// 별 5개와 "(x.x)". 끈 위치를 반 개 단위로 반올림한다 (레거시 updateRating)
private struct RatingRow: View {
    let rating: Double
    let fontSize: CGFloat
    let fontColor: Color
    let starSize: CGFloat
    let onDrag: (Double) -> Void

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { index in
                        starImage(rating, index)
                            .resizable()
                            .frame(width: starSize, height: starSize)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let clampedX = min(max(0, value.location.x), starSize * 5)
                            onDrag(
                                (Double(clampedX / starSize) * 2).rounded(.toNearestOrEven) / 2.0)
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
}

/// 리뷰 정렬 메뉴 (레거시 `SortDropdownView2`)
struct ReviewSortMenu: View {
    let onSelect: (AnimeDetailReducer.ReviewSort) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(AnimeDetailReducer.ReviewSort.allCases, id: \.self) { sort in
                Button {
                    onSelect(sort)
                } label: {
                    Text(sort.rawValue)
                        .textStyle(size: 14, color: .anipickBlack)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.white)
                        .padding(.vertical, 13)
                }

                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundColor(.gray7)
                    .padding(.horizontal, 15)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(width: 91)
    }
}

/// 내 리뷰 ⋮ 메뉴 (레거시 `MyReviewPopupView`)
struct MyReviewMenu: View {
    let deleteAction: () -> Void
    let editAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                Button {
                    deleteAction()
                } label: {
                    Text("삭제")
                        .font(.system(size: 14))
                        .foregroundStyle(.anipickBlack)
                        .padding(15)
                }

                Rectangle()
                    .padding(.horizontal, 15)
                    .foregroundStyle(.gray5)
                    .frame(height: 1)

                Button {
                    editAction()
                } label: {
                    Text("수정")
                        .font(.system(size: 14))
                        .foregroundStyle(.anipickBlack)
                        .padding(15)
                }
            }
            .frame(width: 72)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .border(.gray5)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .cornerRadius(8)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .zIndex(1)
        }
    }
}

/// 리뷰 신고 확인 (레거시 `ReportReviewPopupView`)
struct ReportConfirmPopup: View {
    let cancelAction: () -> Void
    let nextAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("리뷰를 신고하시겠습니까?")
                    .textStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 8)

                Text("신고 시, 리뷰 검토 후 처리됩니다.")
                    .textStyle(size: 14, color: .settingSubTitle)

                Spacer().frame(height: 37)

                HStack {
                    Button {
                        cancelAction()
                    } label: {
                        Text("취소")
                            .textStyle(size: 16, color: .gray6)
                            .frame(maxWidth: .infinity)
                    }

                    Divider()

                    Button {
                        nextAction()
                    } label: {
                        Text("다음")
                            .textStyle(size: 16, color: .anipickPrimary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 22)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .frame(maxWidth: 300)
        }
    }
}

/// 리뷰 작성자 프로필 (인증 이미지). 받기 전·실패하면 초록 원 (레거시 그대로)
struct ReviewerAvatar: View {
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
