import DesignSystem
import DetailClientInterface
import MVICore
import SwiftUI

/// 레거시 `VoiceActorDetailView`와 같은 배치
struct VoiceActorView: View {
    @State private var store: Store<VoiceActorReducer>
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    init(state: VoiceActorReducer.State, reducer: VoiceActorReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    private var state: VoiceActorReducer.State {
        return store.state
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackNavigationBar(title: "성우") {
                store.send(.backTapped)
            }
            .padding(.horizontal, -20)

            Spacer().frame(height: 30)

            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .background(.gray5)
                .padding(.horizontal, -20)

            Spacer().frame(height: 20)

            HStack(alignment: .center, spacing: 0) {
                photo(state.imageUrl, width: 95, height: 95)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.trailing, 20)

                Text(state.name)
                    .textStyle(size: 28, color: .anipickBlack, weight: .bold)
                    .padding(.trailing, 8)

                Button {
                    store.send(.likeTapped)
                } label: {
                    Image(state.isLiked ? .filledHeartPink : .unfilledHeart)
                        .resizable()
                        .frame(width: 19, height: 19)
                }
            }

            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 5)
                .frame(maxWidth: .infinity)
                .background(.gray5)
                .padding(.vertical, 24)

            VStack(alignment: .leading, spacing: 0) {
                Text("참여 작품 목록")
                    .textStyle(size: 16, color: .anipickBlack, weight: .semibold)
                    .padding(.bottom, 20)

                Text("총 \(state.workCount)개")
                    .textStyle(size: 14, color: .gray8, weight: .semibold)
                    .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(state.works, id: \.self) { work in
                            workCell(work)
                                .onAppear {
                                    store.send(.workAppeared(work))
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarBackButtonHidden()
        .padding(.horizontal, 20)
        .background(Color.white)
        .onAppear {
            store.send(.appeared)
        }
    }

    private func workCell(_ work: PersonWork) -> some View {
        return Button {
            store.send(.workTapped(work))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                photo(work.characterImageUrl ?? "", width: nil, height: 105)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(work.characterName)
                    .textStyle(size: 14, color: .anipickBlack)
                    .lineLimit(2)
                    .padding(.top, 6)

                Text(work.animeTitle)
                    .textStyle(size: 12, color: .gray8)
                    .lineLimit(1)
            }
        }
    }

    /// 받는 중·실패·주소 없음이면 기본 썸네일 (레거시 AsyncImage 그대로)
    private func photo(_ url: String, width: CGFloat?, height: CGFloat) -> some View {
        return AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                sized(image, width: width, height: height)
            case .empty, .failure:
                sized(Image(.animeThumbnail), width: width, height: height)
            @unknown default:
                EmptyView()
            }
        }
    }

    private func sized(_ image: Image, width: CGFloat?, height: CGFloat) -> some View {
        return
            image
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .background(Color.gray.opacity(0.3))
            .clipped()
    }
}
