import DesignSystem
import MVICore
import MyInfoClientInterface
import MyInfoInterface
import SwiftUI

/// 레거시 `MyInfoView`와 같은 배치
struct MyInfoMainView: View {
    @State private var store: Store<MyInfoMainReducer>

    init(state: MyInfoMainReducer.State, reducer: MyInfoMainReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header()

                    Spacer().frame(height: 24)

                    feedbackBanner()

                    Spacer().frame(height: 24)

                    HStack(alignment: .center, spacing: 0) {
                        watchStatusButton("볼 애니", store.state.watchListCount, .watchList)
                        watchStatusButton("보는 중", store.state.watchingCount, .watching)
                        watchStatusButton("다 본 애니", store.state.finishedCount, .finished)
                    }

                    Spacer().frame(height: 48)

                    sectionButton("평가한 작품", .ratedReviews)

                    Spacer().frame(height: 32)

                    sectionButton("내 콘텐츠", .myContent)

                    Spacer().frame(height: 32)

                    // 레거시는 화살표 표시 여부를 늘 true로 둔다 (MM10)
                    sectionButton("좋아요한 작품", .likedAnimes)
                        .padding(.bottom, 14)

                    likedAnimes()

                    Spacer().frame(height: 48)

                    sectionButton("좋아요한 인물", .likedPersons)
                        .padding(.bottom, 14)

                    likedPersons()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(
            isPresented: Binding(
                get: { store.state.isImagePickerPresented },
                set: { store.send(.imagePickerPresentedChanged($0)) }
            )
        ) {
            ProfileImagePicker { jpeg in
                store.send(.imagePicked(jpeg))
            } onCancelled: {
                store.send(.imagePickerPresentedChanged(false))
            }
        }
        .padding(.horizontal, 20)
        .background(Color.white)
        .onAppear {
            store.send(.appeared)
        }
    }

    private func header() -> some View {
        return HStack(alignment: .center, spacing: 0) {
            Text("마이페이지")
                .textStyle(size: 24, color: .anipickBlack, weight: .bold)
                .padding(.trailing, 14)

            Button {
                store.send(.settingTapped)
            } label: {
                Image(systemName: "gearshape")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.gray.opacity(0.4))
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
            }

            Spacer()

            ZStack(alignment: .topTrailing) {
                profileImage()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())

                Button {
                    store.send(.editProfileTapped)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.anipickPrimary)
                            .frame(width: 28, height: 28)

                        Image(.editProfileButton)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    }
                    .offset(x: 4, y: 4)
                }
            }
            .frame(width: 76, height: 76)
            .padding(.trailing, 4)
        }
    }

    private func profileImage() -> Image {
        if let data = store.state.profileImage, let image = UIImage(data: data) {
            return Image(uiImage: image)
        }
        return Image(.cloud)
    }

    private func feedbackBanner() -> some View {
        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.298, green: 0.749, blue: 0.690),
                            Color(red: 0.165, green: 0.494, blue: 0.522),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                Text("애니픽을 사용해 보셨나요?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                Text("더 좋은 서비스를 만들 수 있도록\n여러분의 의견을 들려주세요.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                    .padding(.bottom, 16)

                HStack(alignment: .bottom, spacing: 12) {
                    Button {
                        store.send(.feedbackTapped)
                    } label: {
                        Text("바로가기")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.165, green: 0.494, blue: 0.522))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    ZStack {
                        Text("★")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .offset(x: 10, y: -55)

                        Text("★")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .offset(x: -15, y: -65)

                        Text("★")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .offset(x: 25, y: -10)

                        Image(.cloud)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 82)
                    }
                    .frame(width: 110)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private func watchStatusButton(_ title: String, _ count: Int, _ route: MyInfoRoute)
        -> some View
    {
        return Button {
            store.send(.routeTapped(route))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .textStyle(size: 14, color: .anipickBlack, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)

                Text("\(count)개")
                    .textStyle(size: 12, color: .anipickPrimary, weight: .semibold)
                    .frame(maxWidth: .infinity)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(height: 77)
            .background(.gray7)
            .cornerRadius(8)
            .padding(.trailing, 4)
        }
    }

    private func sectionButton(_ title: String, _ route: MyInfoRoute) -> some View {
        return Button {
            store.send(.routeTapped(route))
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Text(title)
                    .textStyle(size: 18, color: .anipickBlack, weight: .black)

                Spacer()

                Image(.chevronRight)
                    .resizable()
                    .frame(width: 18, height: 18)
            }
        }
    }

    @ViewBuilder
    private func likedAnimes() -> some View {
        if store.state.likedAnimes.isEmpty {
            Image(.emptyLikeAnime)
                .resizable()
                .frame(height: 140)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.state.likedAnimes, id: \.self) { anime in
                        Button {
                            store.send(.animeTapped(anime))
                        } label: {
                            TitledCoverImage(
                                url: anime.coverImageUrl, width: 115, height: 162,
                                title: anime.title)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func likedPersons() -> some View {
        if store.state.likedPersons.isEmpty {
            Image(.emptyLikePerson)
                .resizable()
                .frame(height: 140)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.state.likedPersons, id: \.self) { person in
                        Button {
                            store.send(.personTapped(person))
                        } label: {
                            TitledCoverImage(
                                url: person.profileImageUrl, width: 115, height: 144,
                                title: person.name)
                        }
                    }
                }
            }
        }
    }
}
