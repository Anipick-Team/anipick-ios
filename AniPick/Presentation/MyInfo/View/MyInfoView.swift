//
//  MyInfoView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct MyInfoView: View {
    @StateObject var viewModel: MyInfoViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var profileImage: Image? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        Text("마이페이지")
                            .customFontStyle(size: 24, color: .anipickBlack, weight: .bold)
                            .padding(.trailing, 14)

                        Button {
                            DLog("Tapped Setting Button")
                            viewModel.tappedSettingButton()
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
                            if let profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                            } else {
                                Image("cloud-image")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                            }

                            Button {
                                self.showImagePicker.toggle()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.anipickPrimary)
                                        .frame(width: 28, height: 28)

                                    Image("edit-profile-button")
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

                    Spacer().frame(height: 24)

                    // 피드백 배너 카드
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.298, green: 0.749, blue: 0.690),
                                        Color(red: 0.165, green: 0.494, blue: 0.522)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 0) {
                            // 상단: 제목 + 부제목
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

                            // 하단: 버튼 + 구름 이미지
                            HStack(alignment: .bottom, spacing: 12) {
                                Button {
                                    UIApplication.shared.open(URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSdV4UANNQuVanRQ99JLJ1PU9ElXMN2iKx9gPaBXAb0QkVreDg/viewform")!)
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

                                    Image("cloud-image")
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

                    Spacer().frame(height: 24)

                    HStack(alignment: .center, spacing: 0) {
                        getAnimeWatchStatusButton(title: .wantToWatch, countText: viewModel.watchListCount) {
                            self.viewModel.tappedToWatchList()
                        }
                        getAnimeWatchStatusButton(title: .watching, countText: viewModel.watchingCount) {
                            self.viewModel.tappedToWatchingList()
                        }
                        getAnimeWatchStatusButton(title: .finished, countText: viewModel.finishedCount) {
                            self.viewModel.tappedToFinishedAnimeList()
                        }
                    }
                    
                    Spacer().frame(height: 48)
                    
                    self.sectionCategoryButton(title: "평가한 작품", isShownChevron: true) {
                        DLog("평가한 작품 탭으로 이동")
                        self.viewModel.moveToRatedAnimeListView()
                    }
                    
                    Spacer().frame(height: 32)
                    
                    
                    self.sectionCategoryButton(
                        title: "좋아요한 작품",
                        isShownChevron: viewModel.isEmptyLikeAnime
                    ) {
                        DLog("좋아요한 작품 탭으로 이동")
                        self.viewModel.moveToLikedAnimeListView()
                    }
                    .padding(.bottom, 14)
                    
                    if viewModel.likedAnimeList.isEmpty {
                        Image(.emptyLikeAnime)
                            .resizable()
                            .frame(height: 140)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.likedAnimeList, id: \.self) { item in
                                    animationCell(item: item) {
                                        self.viewModel.moveToDetailAnime(animeId: item.animeId ?? 0)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer().frame(height: 48)
                    
                    self.sectionCategoryButton(
                        title: "좋아요한 인물",
                        isShownChevron: viewModel.isEmptyLikePerson
                    ) {
                        DLog("좋아요한 인물 탭으로 이동")
                        self.viewModel.moveToLikedPersonListView()
                    }
                    .padding(.bottom, 14)
                    
                    if viewModel.likedPersonList.isEmpty {
                        Image(.emptyLikePerson)
                            .resizable()
                            .frame(height: 140)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.likedPersonList, id: \.self) { item in
                                    personCell(item: item) {
                                        DLog("좋아요한 인물 cell 탭탭")
                                        self.viewModel.moveToLikedPersionDetailView(id: item.personId ?? 0)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: self.showImagePicker) { newValue in
            if newValue == false {
                viewModel.fetchMyInfo() { image in
                    self.profileImage = image
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .padding(.horizontal, 20)
        .background(Color.white)
        .onAppear {
            viewModel.fetchMyInfo() { image in
                self.profileImage = image
            }
            viewModel.fetchLikePersonList()
            
//            viewModel.getProfileImage() { image in
//                DLog("Image는 성공했음 - \(image) - \(self.viewModel.profileImageId)")
//                self.profileImage = image
//            }
        }
    }
    
    private func personCell(
        item: LikedRatedPerson,
        action: @escaping () -> Void
    ) -> some View {
        return Button {
            action()
        } label: {
            AnimeCommonCellWithTitle(
                imageUrl: item.profileImageUrl,
                width: 115,
                height: 144,
                title: item.name
            )
        }
    }
    
    private func animationCell(item: LikedAnime, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            AnimeCommonCellWithTitle(
                imageUrl: item.coverImageUrl,
                width: 115,
                height: 162,
                title: item.title
            )
        }
    }
    private func sectionCategoryButton(title: String, isShownChevron: Bool, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Text(title)
                    .customFontStyle(size: 18, color: .anipickBlack, weight: .black)
                
                Spacer()
                if isShownChevron {
                    Image("chevron-right")
                        .resizable()
                        .frame(width: 18, height: 18)
                }
            }
        }
    }
    
    private func getAnimeWatchStatusButton(title: AnimationWatchStatus, countText: Int, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(title.title)
                    .customFontStyle(size: 14, color: .anipickBlack, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                
                Text("\(countText)개")
                    .customFontStyle(size: 12, color: .anipickPrimary, weight: .semibold)
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
}



#Preview {
    AppDIContainer.makeMyInfoView()
}
