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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    Text("마이페이지")
                        .customFontStyle(size: 24, color: .anipickBlack, weight: .bold)
                        .padding(.trailing, 14)
                    
                    
                    Button {
                        DLog("Tapped Setting Button")
                        viewModel.tappedSettingButton()
                    } label: {
                        Image(systemName: "gearshape") // SF Symbol 사용
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color.gray.opacity(0.4)) // 아이콘 색상 (연회색)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                }
                
                Spacer().frame(height: 30)
                
                HStack(alignment: .center, spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "person")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 95, height: 95)
                            .clipShape(Circle())
                        
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 34, height: 34)
                            
                            Image("edit-profile-button")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.white) // 필요 시 색상 변경
                        }
                        .offset(x: 6, y: 6) // 살짝 튀어나오게
                    }
                    .frame(width: 100, height: 100)
                    
                    Spacer()
                    
                    let nickname = UserDefaultsManager.shared.getNickname()
                    Text(nickname)
                        .foregroundColor(.anipickPrimary)
                        .font(.system(size: 18, weight: .bold))
                    
                    +  Text("님, 애니픽과 함께\n행복한 애니메이션 생활 즐기세요!")
                        .foregroundColor(.anipickBlack)
                        .font(.system(size: 18, weight: .bold))
                }
                
                Spacer().frame(height: 32)
                
                HStack(alignment: .center, spacing: 0) {
                    getAnimeWatchStatusButton(title: .wantToWatch, countText: viewModel.watchListCount) {
                        self.viewModel.tappedToWatchList()
                    }
                    getAnimeWatchStatusButton(title: .watching, countText: viewModel.watchingCount) {
                        
                    }
                    getAnimeWatchStatusButton(title: .finished, countText: viewModel.finishedCount) {
                        
                    }
                }
                
                Spacer().frame(height: 48)
                
                self.sectionCategoryButton(title: "평가한 작품", isShownChevron: true) {
                    DLog("평가한 작품 탭으로 이동")
                }
                
                Spacer().frame(height: 32)
                
                
                self.sectionCategoryButton(
                    title: "좋아요한 작품",
                    isShownChevron: viewModel.isEmptyLikeAnime
                ) {
                    DLog("좋아요한 작품 탭으로 이동")
                }
                .padding(.bottom, 14)
                
                if viewModel.likedAnimeList.isEmpty {
                    Image(.emptyLikeAnime)
                        .resizable()
                        .frame(height: 140)
                } else {
                    ScrollView {
                        HStack(alignment: .center, spacing: 8) {
                            ForEach(viewModel.likedAnimeList, id: \.self) { item in
                                animationCell(item: item)
                            }
                        }
                    }
                }
                
                Spacer().frame(height: 48)
                
                self.sectionCategoryButton(
                    title: "좋아요한 인물",
                    isShownChevron: viewModel.isEmptyLikePerson
                ) {
                    DLog("좋아요한 작품 탭으로 이동")
                }
                .padding(.bottom, 14)
                
                if viewModel.likedPersonList.isEmpty {
                    Image(.emptyLikePerson)
                        .resizable()
                        .frame(height: 140)
                } else {
                    ScrollView {
                        HStack(alignment: .center, spacing: 8) {
                            ForEach(viewModel.likedPersonList, id: \.self) { item in
                                personCell(item: item)
                            }
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(.chevronLeft)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 20)
            .onAppear {
                viewModel.fetchMyInfo()
            }
        }
    }
    
    private func personCell(item: LikedPerson) -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                if let url = item.profileImageUrl {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 105)
                                .clipped()
                        case .failure:
                            Image(.animeThumbnail)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 105)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(item.name ?? "--")
                .customFontStyle(size: 14, color: .anipickBlack)
                .lineLimit(2)
                .padding(.top, 6)
        }
    }
    
    private func animationCell(item: LikedAnime) -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let url = item.coverImageUrl {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            Image(.animeThumbnail)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipped()
                        case .failure:
                            Image(.animeThumbnail)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(item.title ?? "--")
                .font(.system(size: 14))
                .lineLimit(2)
                .padding(.top, 6)
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
