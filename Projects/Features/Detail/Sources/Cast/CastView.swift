import DesignSystem
import DetailClientInterface
import MVICore
import SwiftUI

/// 레거시 `PersonDetailView`(캐릭터/성우진)와 같은 배치
struct CastView: View {
    @State private var store: Store<CastReducer>
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 2)

    init(state: CastReducer.State, reducer: CastReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackNavigationBar(title: "캐릭터/성우진") {
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

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(store.state.cast, id: \.self) { member in
                        Button {
                            store.send(.memberTapped(member))
                        } label: {
                            CastCell(member: member)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden()
        .background(Color.white)
        .onAppear {
            store.send(.appeared)
        }
    }
}

/// 캐릭터 | 성우 사진 한 쌍과 이름 (레거시 `CharacterAndVoiceActorCellView`). 애니 상세의 캐스트 줄도 쓴다
struct CastCell: View {
    let member: CastMember

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                photo(member.character?.imageUrl ?? "")

                Rectangle()
                    .fill(Color.gray7)
                    .frame(width: 8)

                photo(member.voiceActor?.imageUrl ?? "")
            }
            .clipShape(RoundedCorner(radius: 12, corners: [.topLeft, .topRight]))
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                Text(member.character?.name ?? "")
                    .textStyle(size: 14, color: .anipickBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)

                Text(member.voiceActor?.name ?? "")
                    .textStyle(size: 14, color: .anipickBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 8)
            .background(Color.gray7)
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedCorner(radius: 12, corners: [.bottomLeft, .bottomRight]))
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
        .clipped()
    }

    /// 받는 중·실패·주소 없음이면 기본 썸네일 (레거시 AsyncImage 그대로)
    private func photo(_ url: String) -> some View {
        return AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                sized(image)
            case .empty, .failure:
                sized(Image(.animeThumbnail))
            @unknown default:
                EmptyView()
            }
        }
    }

    private func sized(_ image: Image) -> some View {
        return
            image
            .resizable()
            .scaledToFill()
            .frame(height: 95)
            .background(Color.gray.opacity(0.3))
            .clipped()
    }
}

/// 일부 모서리만 둥근 사각형 (레거시 `RoundedCorner`)
nonisolated struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
