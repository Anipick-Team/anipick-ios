import DesignSystem
import HomeClientInterface
import MVICore
import SwiftUI

/// 레거시 `HomeView`와 같은 배치
struct HomeMainView: View {
    @State private var store: Store<HomeMainReducer>
    @Environment(\.openURL) private var openURL

    init(state: HomeMainReducer.State, reducer: HomeMainReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    private var state: HomeMainReducer.State {
        return store.state
    }

    var body: some View {
        VStack(spacing: 0) {
            header()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 100) {
                    VStack(spacing: 0) {
                        InstagramBanner {
                            if let url = URL(string: InstagramBanner.url) {
                                openURL(url)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 28)

                        sectionHeader(title: Text(verbatim: "실시간 인기 애니메이션")) {
                            store.send(.rankingTapped)
                        }

                        Spacer().frame(height: 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(state.trending, id: \.self) { item in
                                    Button {
                                        store.send(.animeTapped(animeId: item.animeId))
                                    } label: {
                                        HomeAnimeCard(
                                            imageUrl: item.coverImageUrl, title: item.title,
                                            rank: item.rank)
                                    }
                                    .padding(.trailing, 12)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    if state.recommendations.isEmpty {
                        Image(.emptyRecommendation)
                    } else if let title = state.referenceTitle {
                        sectionView(
                            title: highlightedTitle(title, " 을 재밌게 보셨다면,\n이 작품들도 마음에 드실 거에요!"),
                            items: state.recommendations
                        ) {
                            store.send(.recommendationsTapped)
                        }
                    } else {
                        sectionView(
                            title: highlightedTitle(
                                prefix: "오늘의 추천작, ", state.nickname, " 님의\n취향에 맞춰 준비했어요!"),
                            items: state.recommendations
                        ) {
                            store.send(.recommendationsTapped)
                        }
                    }

                    weekdaySection()

                    VStack(alignment: .leading, spacing: 0) {
                        sectionHeader(title: Text(verbatim: "최근 리뷰")) {
                            store.send(.recentReviewsTapped)
                        }
                        .padding(.bottom, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                recentReviewCards()
                                    .padding(.trailing, 12)
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    sectionView(
                        title: highlightedTitle("\(state.seasonYear)년도 \(state.season)분기", " 방영예정"),
                        items: state.upcoming
                    ) {
                        store.send(.upcomingTapped)
                    }

                    if state.hasRecentSimilar {
                        sectionView(
                            title: highlightedTitle(
                                prefix: "최근 찾아보신 ", state.similarTitle, "과\n비슷한 작품이에요!"),
                            items: state.similar
                        ) {
                            store.send(.similarTapped)
                        }
                    } else {
                        Image(.emptyRecentViewed)
                            .accessibilityLabel("아직 찾아본 애니가 없어요. 다양한 애니를 탐색해 보세요!")
                    }

                    sectionView(title: Text(verbatim: "공개 예정"), items: state.comingSoon) {
                        store.send(.comingSoonTapped)
                    }
                }
            }
            .background(.gray7)
        }
        .navigationBarBackButtonHidden(true)
        .background(Color.white)
        .onAppear {
            store.send(.appeared)
        }
    }

    private func header() -> some View {
        return HStack(spacing: 0) {
            Image(.aniPickLogoGreen)
                .resizable()
                .frame(width: 110, height: 22)

            Spacer()

            Button {
                store.send(.searchTapped)
            } label: {
                Image(.searchIconsGray)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .frame(height: 60)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 2)
                .foregroundStyle(.gray6)
        }
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
        .zIndex(1)  // 그림자가 아래 스크롤 영역에 가려지지 않도록
    }

    private func sectionHeader(title: Text, action: @escaping () -> Void) -> some View {
        return HStack(alignment: .top, spacing: 0) {
            title
                .textStyle(size: 18, color: .anipickBlack, weight: .bold)
                .lineSpacing(4)  // 줄 높이 25.2pt(140%)에 맞춘 근사값
                .padding(.vertical, 2)
                .multilineTextAlignment(.leading)

            Spacer()

            Button {
                action()
            } label: {
                Image(.chevronLeftGray)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 20)
    }

    private func highlightedTitle(prefix: String = "", _ highlight: String, _ suffix: String)
        -> Text
    {
        return Text(
            "\(Text(verbatim: prefix))\(Text(verbatim: highlight).foregroundColor(.anipickPrimary))\(Text(verbatim: suffix))"
        )
    }

    private func sectionView(title: Text, items: [HomeAnime], action: @escaping () -> Void)
        -> some View
    {
        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: title, action: action)
                .padding(.bottom, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(items, id: \.self) { item in
                        cell(item)
                            .padding(.trailing, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func cell(_ anime: HomeAnime) -> some View {
        return Button {
            store.send(.animeTapped(animeId: anime.animeId))
        } label: {
            HomeAnimeCard(imageUrl: anime.coverImageUrl, title: anime.title)
        }
    }

    private func weekdaySection() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: Text(verbatim: "요일별 신작")) {
                store.send(.weekdayTapped)
            }
            .padding(.bottom, 20)

            HStack(spacing: 0) {
                ForEach(WeekdayNewAnimeDay.allCases) { day in
                    let isSelected = state.selectedWeekday == day
                    Button {
                        store.send(.weekdaySelected(day))
                    } label: {
                        Text(day.title)
                            .textStyle(
                                size: 18, color: isSelected ? .white : .textGray, weight: .bold
                            )
                            .frame(width: 45, height: 45)
                            .background(isSelected ? Color.anipickPrimary : Color.gray6)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    if day != WeekdayNewAnimeDay.allCases.last {
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(state.weekdayAnimes, id: \.self) { item in
                        cell(item)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func recentReviewCards() -> some View {
        return ForEach(state.recentReviews, id: \.self) { item in
            Button {
                store.send(.recentReviewsTapped)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.animeTitle ?? "--")
                            .textStyle(size: 12, color: .textGray, weight: .medium)
                            .lineLimit(1)

                        Text(item.reviewContent ?? "--")
                            .textStyle(size: 16, color: .anipickBlack, weight: .medium)
                            .lineSpacing(3)  // 줄 높이 22.4pt(140%)에 맞춘 근사값
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .frame(height: 50, alignment: .topLeading)
                    }

                    Spacer(minLength: 16)

                    HStack(spacing: 8) {
                        Text(item.nickname ?? "--")
                            .lineLimit(1)

                        Rectangle()
                            .frame(width: 1, height: 10)

                        Text(Self.reviewDateText(item.createdAt))
                            .fixedSize()
                    }
                    .textStyle(size: 12, color: .textGray, weight: .medium)
                }
                .frame(width: 197, height: 112, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray6, lineWidth: 1)
                }
            }
        }
    }

    /// "2026-10-30T…" → "2026.10.30". 날짜 꼴이 아니면 그대로 (없으면 "--")
    static func reviewDateText(_ raw: String?) -> String {
        guard let raw else {
            return "--"
        }
        let prefix = String(raw.prefix(10))
        let isDate =
            prefix.range(of: #"^\d{4}[-.]\d{2}[-.]\d{2}$"#, options: .regularExpression) != nil
        return isDate ? prefix.replacingOccurrences(of: "-", with: ".") : raw
    }
}

/// 홈 위쪽 인스타그램 배너 (레거시 `InstagramBannerView`)
struct InstagramBanner: View {
    static let url = "https://www.instagram.com/anipick.official?igsh=Y2tkc2k1M3FmNDll"
    let onFollowTapped: () -> Void

    private let blue = Color(red: 0.18, green: 0.6, blue: 0.9)

    var body: some View {
        ZStack {
            Color(red: 0.88, green: 0.94, blue: 1.0)

            HStack(spacing: 0) {
                Image(.instagramIconSmall)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .padding(.leading, 4)

                Spacer()

                Image(.instagramIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            }

            VStack(spacing: 6) {
                HStack(alignment: .center, spacing: 4) {
                    Text("[")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundColor(blue)

                    Text(
                        "\(Text("애니픽 ").foregroundColor(.black))\(Text("공식 인스타그램").foregroundColor(blue))\(Text(" 오픈!").foregroundColor(.black))"
                    )
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                    Text("]")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundColor(blue)
                }

                Text("다양한 애니메이션 소식과 최신 업데이트 소식을\n가장 빠르게 확인해보세요!")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Button {
                    onFollowTapped()
                } label: {
                    Text("팔로우 하러 가기")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }
}

/// 홈 가로 목록의 작품 카드 (레거시 `HomeAnimeCard`). 순위가 있으면 왼쪽 위에 표시
struct HomeAnimeCard: View {
    let imageUrl: String?
    let title: String?
    var rank: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnimeCoverImage(
                url: imageUrl, width: 128, height: 182, cornerRadius: 8, contentMode: .fill
            )
            .overlay(alignment: .topLeading) {
                if let rank {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.anipickPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(10)
                }
            }

            Text(title ?? "--")
                .textStyle(size: 16, color: .anipickBlack, weight: .medium)
                .lineSpacing(3)  // 줄 높이 140%(22.4pt)에 맞춘 근사값
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 128, height: 45, alignment: .topLeading)
        }
    }
}
