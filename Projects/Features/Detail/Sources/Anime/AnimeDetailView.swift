import DesignSystem
import DetailClientInterface
import MVICore
import SwiftUI
import UIKit

/// 레거시 `AnimationInfoView`와 같은 배치. 머리가 접혔는지(스크롤 -120)는 레이아웃 상태라 View가 들고 있다.
struct AnimeDetailView: View {
    @State private var store: Store<AnimeDetailReducer>
    @State private var headerCollapsed = false
    @State private var width: CGFloat = 0
    private let imageURL: (Int) -> URL

    init(
        state: AnimeDetailReducer.State, reducer: AnimeDetailReducer,
        imageURL: @escaping (Int) -> URL
    ) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
        self.imageURL = imageURL
    }

    private var state: AnimeDetailReducer.State {
        return store.state
    }

    var body: some View {
        ZStack {
            EnableSwipeBackGesture()
                .frame(width: 0, height: 0)

            ScrollView(showsIndicators: false) {
                // 스크롤 위치를 재는 자리 (레거시: 리뷰 메뉴를 닫는 데 쓴다). 아래 내용과 기본 간격 8이 생기는 것도 레거시 그대로
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global).minY) {
                            if store.state.isMyReviewMenuPresented
                                || store.state.isBlockMenuPresented
                            {
                                store.send(.scrolled)
                            }
                        }
                }
                .frame(height: 0)

                VStack(spacing: 0) {
                    GeometryReader { geo in
                        let minY = geo.frame(in: .global).minY
                        banner(width: geo.size.width)
                            .ignoresSafeArea(edges: .top)
                            .padding(.bottom, 25)
                            .onChange(of: minY) { _, newValue in
                                headerCollapsed = newValue < -120
                            }
                    }
                    .frame(height: 280)

                    if let info = state.info {
                        content(info)
                            .padding(.horizontal, state.selectedTab == .reviews ? 10 : 20)
                    }
                }
            }

            reviewPopups()

            if let url = state.previewImageURL {
                ImagePreviewPopup(imageURL: url) {
                    store.send(.previewClosed)
                }
                .zIndex(1001)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            return proxy.size.width
        } action: { newWidth in
            width = newWidth
        }
        .overlay(alignment: .top) {
            if headerCollapsed {
                collapsedHeader()
            }
        }
        .overlay {
            if state.isCommunityMissingPresented {
                CommunityMissingPopup(animeTitle: state.info?.title ?? "애니메이션") {
                    store.send(.communityMissingClosed)
                } inquiryAction: {
                    store.send(.communityInquiryTapped)
                }
            }
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            store.send(.appeared)
        }
        .onDisappear {
            store.send(.disappeared)
        }
        .navigationBarBackButtonHidden()
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                if state.isBlockToastPresented {
                    toast("사용자 차단이 완료되었습니다.")
                }
                if state.isReportToastPresented {
                    toast("신고가 정상적으로 접수되었습니다.")
                }
                if state.isRatingToastPresented {
                    toast("리뷰가 성공적으로 작성되었습니다!")
                }
            }
        }
        .animation(.default, value: state.isBlockToastPresented)
        .animation(.default, value: state.isReportToastPresented)
        .animation(.default, value: state.isRatingToastPresented)
    }

    /// 리뷰 메뉴와 신고·차단 창 (레거시 상세 화면 맨 위)
    @ViewBuilder
    private func reviewPopups() -> some View {
        if state.isBlockConfirmPresented {
            BlockUserPopup {
                store.send(.blockCancelled)
            } okAction: {
                store.send(.blockConfirmed)
            }
        }

        if state.isReportConfirmPresented {
            ReportConfirmPopup {
                store.send(.reportConfirmCancelled)
            } nextAction: {
                store.send(.reportConfirmNextTapped)
            }
        }

        if state.isReportReasonPresented {
            ReportReasonPopup {
                store.send(.reportReasonCancelled)
            } okAction: { reason in
                store.send(.reportReasonConfirmed(reason))
            }
        }

        // 레거시: 화면 너비 - 70, ⋮ 버튼 아래 + 60
        if state.isMyReviewMenuPresented {
            MyReviewMenu {
                store.send(.myReviewDeleteTapped)
            } editAction: {
                store.send(.myReviewEditTapped)
            }
            .position(x: width - 70, y: state.menuAnchorMaxY + 60)
            .zIndex(1000)
        }

        if state.isBlockMenuPresented {
            ReportBlockMenu {
                store.send(.reportMenuTapped)
            } blockAction: {
                store.send(.blockMenuTapped)
            }
            .position(x: width - 70, y: state.menuAnchorMaxY + 60)
            .zIndex(1000)
        }
    }

    private func toast(_ message: String) -> some View {
        return Text(message)
            .textStyle(size: 14, color: .gray5)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.anipickBlack)
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - 배너·표지

    private func banner(width: CGFloat) -> some View {
        return ZStack(alignment: .top) {
            if let bannerURL = state.bannerURL {
                ZStack {
                    AsyncImage(url: bannerURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: width, height: 280)
                                .clipped()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.imageTapped(bannerURL))
                                }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityLabel("배너 원본 보기")
                        case .empty, .failure:
                            Image(.animeThumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(width: width, height: 280)
                                .clipped()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .ignoresSafeArea(edges: .top)

                    Color.black.opacity(0.4)
                        .frame(width: width, height: 280)
                        .allowsHitTesting(false)
                }
            } else {
                Image(.emptyBackgroundImg)
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .ignoresSafeArea(edges: .top)
            }

            HStack(alignment: .top, spacing: 0) {
                ZStack {
                    HStack(alignment: .center, spacing: 0) {
                        Button {
                            store.send(.backTapped)
                        } label: {
                            Image(.chevronLeftStroke)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .padding(.leading, 20)

                        Spacer()
                    }

                    Spacer()
                }
                .padding(.top, 54)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    if let url = state.info?.coverImageUrl {
                        cover(url)
                    }
                }
            }
            .padding(.horizontal, state.selectedTab == .reviews ? -10 : 0)
        }
    }

    private func cover(_ url: String) -> some View {
        return AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 133, height: 154)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(
                            Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.send(.imageTapped(store.state.coverURL))
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("표지 원본 보기")
                    .padding(.bottom, 23)
                    .padding(.trailing, 20)
            case .empty, .failure:
                Image(.animeThumbnail)
                    .resizable()
                    .frame(width: 133, height: 154)
                    .padding(.bottom, 23)
                    .padding(.trailing, 20)
                    .cornerRadius(8)
            @unknown default:
                EmptyView()
            }
        }
    }

    // MARK: - 본문

    private func content(_ info: AnimeInfo) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Text(info.title ?? "--")
                    .textStyle(size: 20, color: .anipickBlack, weight: .semibold)
                    .padding(.trailing, 12)

                likeButton()

                Spacer()

                Button {
                    store.send(.shareTapped)
                } label: {
                    Image(.shareButton)
                }
            }
            .padding(.bottom, 8)
            .padding(.top, 8)

            HStack(alignment: .center, spacing: 0) {
                Image(.fillPickStar)
                    .resizable()
                    .frame(width: 18, height: 18)

                Text(state.averageRating)
                    .textStyle(size: 14, color: .point, weight: .semibold)
                    .padding(.leading, 8)
                    .lineLimit(1)
                    .fixedSize()
            }

            Spacer().frame(height: 32)

            HStack(alignment: .center, spacing: 4) {
                watchButton(.wantToWatch)
                watchButton(.watching)
                watchButton(.finished)
            }
            .frame(maxWidth: .infinity)

            Spacer().frame(height: 23)

            Rectangle()
                .frame(height: 3)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, -40)
                .foregroundStyle(.gray5)

            Spacer().frame(height: 20)

            tabs()
                .padding(.bottom, 13)

            switch state.selectedTab {
            case .info:
                AnimeInfoTab(info: info, state: state) { store.send($0) }
            case .reviews:
                AnimeReviewsTab(state: state, imageURL: imageURL) { store.send($0) }
            case .community:
                EmptyView()
            }

            Spacer().frame(height: 30)
        }
    }

    private func likeButton() -> some View {
        return Button {
            store.send(.likeTapped)
        } label: {
            Image(state.isLiked ? .fillHeartGreen : .unfilledHeart)
                .resizable()
                .frame(width: 19, height: 19)
        }
    }

    private func watchButton(_ status: AnimeDetailReducer.WatchStatus) -> some View {
        let isSelected = status == state.watchStatus
        return Button {
            store.send(.watchStatusTapped(status))
        } label: {
            Text(status.rawValue)
                .textStyle(size: 14, color: isSelected ? .white : .anipickBlack)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? .anipickPrimary : .gray5)
                .cornerRadius(8)
        }
    }

    private func tabs() -> some View {
        return HStack(alignment: .center, spacing: 0) {
            tab(.info)
            tab(.reviews)
            tab(.community)
        }
    }

    private func tab(_ tab: AnimeDetailReducer.Tab) -> some View {
        let isSelected = tab == state.selectedTab
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                // 커뮤니티는 탭을 바꾸지 않고 게시판을 연다
                store.send(tab == .community ? .communityTapped : .tabSelected(tab))
            } label: {
                Text(tab == .reviews ? "\(tab.rawValue)(\(state.reviewCount)개)" : tab.rawValue)
                    .textStyle(size: 14, color: isSelected ? .anipickBlack : .gray6)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(
                tab == .community ? "communityTab" : "animationInfoTab_\(tab.rawValue)"
            )
            .accessibilityLabel(tab.rawValue)

            if isSelected {
                Rectangle()
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.gray5)
            } else {
                Color.clear.frame(height: 2)
            }
        }
    }

    private func collapsedHeader() -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(.chevronLeftStroke)
                        .resizable()
                        .frame(width: 24, height: 24)
                }

                Spacer()

                Text(state.info?.title ?? "--")
                    .textStyle(size: 18, color: .anipickBlack, weight: .semibold)
                    .lineLimit(1)
                    .padding(.leading, 12)
                    .padding(.trailing, 8)

                likeButton()

                Spacer()
            }
            .padding(.bottom, 12)

            HStack(alignment: .center, spacing: 0) {
                tab(.info)
                tab(.reviews)
                if state.info != nil {
                    tab(.community)
                }
            }
            .padding(.bottom, 13)
        }
        .padding(.top, Self.topSafeArea)
        .padding(.bottom, 12)
        .padding(.horizontal, 20)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .background(Color.white)
    }

    /// 레거시 `UIApplication.shared.windows.first?.safeAreaInsets.top ?? 20`
    private static var topSafeArea: CGFloat {
        let window = UIApplication.shared.connectedScenes.compactMap {
            ($0 as? UIWindowScene)?.windows.first
        }.first
        return window?.safeAreaInsets.top ?? 20
    }
}

/// "작품 정보" 탭 (레거시 `AnimationDetailInfoView`)
struct AnimeInfoTab: View {
    let info: AnimeInfo
    let state: AnimeDetailReducer.State
    let send: (AnimeDetailReducer.Intent) -> Void
    @State private var lineLimit: Int? = 3
    @State private var collapsedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    private enum Row: String, CaseIterable {
        case type = "타입"
        case genre = "장르"
        case release = "방영 시기"
        case episode = "에피소드"
        case ageRating = "연령 등급"
        case studio = "제작사"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let description = info.description ?? "--"
            Text(description)
                .textStyle(size: 14, color: .anipickBlack)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
                .overlay(heightProbes(description))

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
            }

            Spacer().frame(height: 20)

            Rectangle()
                .frame(height: 3)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, -40)
                .foregroundStyle(.gray5)

            Spacer().frame(height: 33)

            ForEach(Row.allCases, id: \.self) { row in
                HStack(alignment: .top, spacing: 0) {
                    Text(row.rawValue)
                        .textStyle(size: 14, color: .anipickBlack)
                        .padding(.vertical, 10)

                    Spacer()

                    value(row)
                }
            }

            Spacer().frame(height: 60)

            sectionButton("캐릭터/성우진") {
                send(.castHeaderTapped)
            }
            .padding(.bottom, 20)

            horizontalList {
                ForEach(state.cast, id: \.self) { member in
                    CastCell(member: member)
                        .onTapGesture {
                            send(.castTapped(member))
                        }
                }
            }
            .padding(.horizontal, -20)
            .padding(.bottom, 20)

            if !state.series.isEmpty {
                sectionButton("관련 작품") {
                    send(.seriesHeaderTapped)
                }
                .padding(.bottom, 20)

                horizontalList {
                    animeCells(state.series)
                }
                .padding(.horizontal, -20)
                .padding(.bottom, 20)

                Spacer().frame(height: 48)
            }

            if !state.recommendations.isEmpty {
                sectionButton("함께 볼만한 작품") {
                    send(.recommendationsHeaderTapped)
                }
                .padding(.bottom, 20)

                // 레거시: 이 줄만 좌우 여백을 상쇄하지 않는다
                horizontalList {
                    animeCells(state.recommendations)
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color.white)
    }

    private func horizontalList(@ViewBuilder _ content: () -> some View) -> some View {
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .center, spacing: 8) {
                content()
            }
            .padding(.horizontal, 12)
        }
        .contentShape(Rectangle())
        .clipped()
        .scrollDisabled(false)
    }

    private func animeCells(_ animes: [DetailAnime]) -> some View {
        return ForEach(animes, id: \.self) { anime in
            TitledCoverImage(url: anime.coverImageUrl, width: 115, height: 162, title: anime.title)
                .onTapGesture {
                    send(.animeTapped(animeId: anime.animeId))
                }
        }
    }

    @ViewBuilder
    private func value(_ row: Row) -> some View {
        switch row {
        case .type:
            plain(info.type ?? "-")
        case .genre:
            HStack(alignment: .center, spacing: 0) {
                ForEach(Array((info.genres ?? []).enumerated()), id: \.offset) { _, genre in
                    GenreTagChip(title: genre)
                }
            }
        case .release:
            HStack(alignment: .center, spacing: 0) {
                Text(info.status ?? "-")
                    .textStyle(size: 14, color: .anipickBlack)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 16)
                    .background(.gray5)
                    .cornerRadius(32)
                    .padding(.trailing, 12)

                plain(info.airDate ?? "-")
            }
        case .episode:
            if let episode = info.episode {
                plain("\(episode)회차")
            } else {
                Text("-")
            }
        case .ageRating:
            plain("\(info.age ?? "-") 이상 시청")
        case .studio:
            if let studios = info.studios {
                FlowChipLayout(spacing: 4, alignTrailing: true) {
                    ForEach(studios, id: \.self) { studio in
                        if let name = studio.name {
                            Button {
                                send(.producerTapped(studioId: studio.studioId))
                            } label: {
                                Text(name)
                                    .textStyle(size: 14, color: .anipickSecondary)
                                    .underline(true, color: .anipickSecondary)
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
    }

    private func plain(_ text: String) -> some View {
        return Text(text)
            .textStyle(size: 14, color: .gray8)
    }

    private func sectionButton(_ title: String, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Text(title)
                    .textStyle(size: 18, color: .anipickBlack, weight: .black)

                Spacer()

                Image(.chevronRight)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.gray6)
            }
        }
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

/// 장르 태그 (레거시 `GerneTagComponents`)
struct GenreTagChip: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .textStyle(size: 12, color: .anipickPrimary)
                .background(Color.anipickPrimary.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.leading, 4)
    }
}

/// 원본 이미지 보기 (레거시 `ImagePreviewPopupView`)
struct ImagePreviewPopup: View {
    let imageURL: URL
    let closeAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: closeAction)

            VStack(spacing: 0) {
                RemoteImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 160)
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("원본 이미지")

                Button(action: closeAction) {
                    Text("닫기")
                        .textStyle(size: 16, color: .anipickPrimary, weight: .medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
    }
}

/// 커뮤니티가 없을 때 (레거시 `CommunityNotCreatedPopupView`)
struct CommunityMissingPopup: View {
    let animeTitle: String
    let cancelAction: () -> Void
    let inquiryAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("알림")
                    .textStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 8)

                Text("'\(animeTitle)'의 커뮤니티는 아직 생성되지 않았습니다.\n커뮤니티 생성을 원하실 경우 문의해 주세요.")
                    .textStyle(size: 14, color: .settingSubTitle)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 37)

                HStack {
                    Button {
                        cancelAction()
                    } label: {
                        Text("닫기")
                            .textStyle(size: 16, color: .gray6)
                            .frame(maxWidth: .infinity)
                    }

                    Divider()

                    Button {
                        inquiryAction()
                    } label: {
                        Text("문의하기")
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

/// 뒤로 버튼을 숨긴 화면에서도 밀어서 뒤로 가기를 켠다 (레거시 `EnableSwipeBackGesture`)
struct EnableSwipeBackGesture: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            if let navigationController = controller.navigationController {
                navigationController.interactivePopGestureRecognizer?.isEnabled = true
                navigationController.interactivePopGestureRecognizer?.delegate = nil
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
