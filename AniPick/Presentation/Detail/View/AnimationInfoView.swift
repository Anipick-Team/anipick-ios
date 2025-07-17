//
//  AnimationInfoView.swift
//  AniPick
//
//  Created by cho on 5/25/25.
//

import SwiftUI

struct AnimationInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AnimationInfoViewModel
    @State private var starRating: Int = 0
    @State private var selectedAnimationStatusTab: AnimationWatchStatus = .wantToWatch
    @State private var selectedInfoTab: AnimationInfoTab = .reviewInfo
    @State private var selectedSortOption: SortOption = .latest
    
    @State private var isActiveLike: Bool = false
    
    var body: some View {
        ScrollView {
            // TODO: 애니메이션 이미지 넣어야함
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .foregroundColor(.gray7)
                    
                    HStack(alignment: .top, spacing: 0) {
                        NavigationBackButtonView(title: "") {
                            dismiss()
                        }
                        .padding(.top, 54)
                                                
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                            Image(.animeThumbnail)
                                .resizable()
                                .frame(width: 133, height: 154)
                                .padding(.bottom, 23)
                                .padding(.trailing, 20)
                        }
                    }
                }
                .padding(.bottom, 25)
                
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        Text("록은 숙녀의 소양이기에")
                            .customFontStyle(size: 20, color: .anipickBlack, weight: .semibold)
                            .padding(.trailing, 12)
                        
                        // TODO: 눌렀을 때 좋아요 처리해야함
                        Button {
                            DLog("누르면 좋아요 처리")
                            self.isActiveLike.toggle()
                        } label: {
                            Image(self.isActiveLike ? .fillHeartGreen : .unfilledHeart)
                                .resizable()
                                .frame(width: 19, height: 19)
                        }
                        
                        Spacer()
                        
                        Button {
                            DLog("공유버튼 탭탭")
                        } label: {
                            Image(.shareButton)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    HStack(alignment: .center, spacing: 0) {
                        
                        Image(.fillPickStar)
                            .resizable()
                            .frame(width: 18, height: 18)
                        
                        Text("\(self.starRating, specifier: "%.1f")")
                            .customFontStyle(size: 14, color: .point, weight: .semibold)
                            .padding(.leading, 8)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    
                    Spacer().frame(height: 32)
                    
                    HStack(alignment: .center, spacing: 0) {
                        animationWatchState(title: .wantToWatch)
                        animationWatchState(title: .watching)
                        animationWatchState(title: .finished)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer().frame(height: 23)
                    
                    Rectangle()
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, -40)
                        .foregroundStyle(.gray5)
                    
                    Spacer().frame(height: 20)
                    
                    HStack(alignment: .center, spacing: 0) {
                        selectedTab(title: .animationInfo)
                        selectedTab(title: .reviewInfo, animationCount: 3128)
                    }
                    .padding(.bottom, 13)
                    
                    
                    if self.selectedInfoTab == .animationInfo {
                        AnimationDetailInfoView()
                    } else if self.selectedInfoTab == .reviewInfo {
                        ReviewDetailInfoView(
                            selectedSortOption: self.$selectedSortOption,
                            isShowOnlyReview: self.$viewModel.isShowOnlyReview,
                            isShowSortOptionView: self.$viewModel.isShowSortOptionView,
                            starRating: self.$starRating
                        )
                    }
                    Spacer().frame(height: 30)
                    
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden()
    }
        
    private func animationWatchState(title: AnimationWatchStatus) -> some View {
        Button {
            DLog("\(title.title) 탭탭")
            self.selectedAnimationStatusTab = title
        } label: {
            Text(title.title)
                .customFontStyle(size: 14, color: title == self.selectedAnimationStatusTab ? .white : .anipickBlack)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(title == self.selectedAnimationStatusTab ? .anipickPrimary : .gray5)
                .cornerRadius(8)
        }
        .padding(.horizontal, 2)
    }
    
    private func selectedTab(title: AnimationInfoTab, animationCount: Int = 0) -> some View {
        VStack(alignment: .leading, spacing: 0) {
                Button {
                    DLog("\(title.title) 탭탭")
                    self.selectedInfoTab = title
                } label: {
                    if title.title == "리뷰" {
                        Text("\(title.title)(\(animationCount)개)")
                            .customFontStyle(size: 14, color: title == self.selectedInfoTab ? .anipickBlack : .gray6)
                            .padding(.bottom, 8)
                    } else {
                        Text(title.title)
                            .customFontStyle(size: 14, color: title == self.selectedInfoTab ? .anipickBlack : .gray6)
                            .padding(.bottom, 8)
                    }
                }
                .frame(maxWidth: .infinity)
            
            if title == self.selectedInfoTab {
                Rectangle()
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.gray5) // 선택된 탭 표시 색상
            } else {
                Color.clear.frame(height: 2)
            }
        }
    }
}


struct CharacterVoiceActorCell: View {
    var characterName: String
    var actorName: String
    var characterImage: Image = Image(systemName: "person.fill") // 예시용 이미지
    var actorImage: Image = Image(systemName: "person.fill")     // 예시용 이미지

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 캐릭터 이미지
                characterImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 91, height: 95)
                    .background(Color.gray.opacity(0.3))
                    .clipped()
                
                Rectangle()
                       .fill(Color.gray7)
                       .frame(width: 8)

                // 성우 이미지
                actorImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 91, height: 95)
                    .background(Color.gray.opacity(0.3))
                    .clipped()
            }
            .frame(width: 190)

            HStack(spacing: 0) {
                Text(characterName)
                    .customFontStyle(size: 14, color: .anipickBlack)
                    .frame(maxWidth: .infinity)

                Text(actorName)
                    .customFontStyle(size: 14, color: .anipickBlack)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(Color(red: 248/255, green: 249/255, blue: 253/255)) // 연한 회색
        }
        .frame(width: 190)
        .cornerRadius(16)
        .clipped()
    }
}


enum AnimationDetailInfo: String, CaseIterable {
    case type = "타입"
    case gerne = "장르"
    case release = "방영 시기"
    case episode = "에피소드"
    case ageRating = "연령 등급"
    case productionCompany = "제작사"
    
    var title: String { self.rawValue }
}

enum AnimationWatchStatus: String, CaseIterable {
    case wantToWatch = "볼 애니"
    case watching = "보는 중"
    case finished = "다 본 애니"
    
    var title: String { self.rawValue }
}

enum AnimationInfoTab: String, CaseIterable {
    case animationInfo = "작품 정보"
    case reviewInfo = "리뷰"
    
    var title: String { self.rawValue }
}
#Preview {
    AppDIContainer.makeAnimeDetailView(animeId: 0)
}
