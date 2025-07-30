//
//  AnimationDetailInfoView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct AnimationDetailInfoView: View {
    let detailInfo: AnimeDetail
    let seriesInfo: [SeriesAnime]
    let recommendationInfo: [Anime]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(detailInfo.description ?? "--")
                .customFontStyle(size: 14, color: .anipickBlack)
                .lineLimit(3)
                .padding(.bottom, 16)
            
            HStack(alignment: .center, spacing: 0) {
                Button {
                    DLog("더보기 버튼 탭탭")
                } label: {
                    HStack(alignment: .center, spacing: 0) {
                        Text("더보기")
                            .font(.system(size: 14))
                            .foregroundStyle(.anipickPrimary)
                            .padding(.trailing, 4)
                        
                        Image(.chevronDownPrimary)
                    }
                }
                
                Spacer()
            }
            
            Spacer().frame(height: 20)
            
            Rectangle()
                .frame(height: 3)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, -40)
                .foregroundStyle(.gray5)
            
            Spacer().frame(height: 33)
            
            ForEach(AnimationDetailInfo.allCases, id: \.self) { value in
                HStack(alignment: .center, spacing: 0) {
                    Text(value.title)
                        .customFontStyle(size: 14, color: .anipickBlack)
                        .padding(.vertical, 10)
                    
                    Spacer()
                    
                    infoView(value: value, detailInfo: detailInfo)
                }
            }
            
            Spacer().frame(height: 60)
            
            self.sectionCategoryButton(title: "캐릭터/성우진") {
                DLog("캐릭터 성우진 상세로 이동")
            }
            .padding(.bottom, 20)
            
            // TODO: 캐릭터, 성우진만 넣으면 UI가 깨짐 확인 필요 및 UI 수정
//            HStack(alignment: .center, spacing: 8) {
//                CharacterVoiceActorCell(characterName: "캐릭터명", actorName: "성우명")
//                CharacterVoiceActorCell(characterName: "캐릭터명", actorName: "성우명")
//            }
            
            
            self.sectionCategoryButton(title: "시리즈 정보") {
                DLog("시리즈 정보로 이동")
            }
            .padding(.bottom, 20)
            
            
            ForEach(seriesInfo, id: \.self) { item in
                HStack(alignment: .center, spacing: 8) {
                    self.animationCell(title: item.title ?? "--", subtitle: item.airDate ?? "--")
                }
            }
            
            
            Spacer().frame(height: 48)
            
            
            self.sectionCategoryButton(title: "함께 볼 만한 작품") {
                DLog("함께 볼만한 작품으로 이동")
            }
            .padding(.bottom, 20)
            
            
            ForEach(recommendationInfo, id: \.self) { item in
                HStack(alignment: .center, spacing: 8) {
                    self.animationCell(title: item.title ?? "--", subtitle: "")
                }
            }
        }
    }
    
    @ViewBuilder
    private func infoView(value: AnimationDetailInfo, detailInfo: AnimeDetail) -> some View {
        switch value {
        case .type:
            infoTextView(string: detailInfo.type ?? "-")
        case .gerne:
            HStack(alignment: .center, spacing: 0) {
                let genres = detailInfo.genres ?? []
                ForEach(genres) { genre in
                    GerneTagComponents(title: genre.name)
                }
            }
        case .release:
            HStack(alignment: .center, spacing: 0) {
                animationFinishedTag(title: detailInfo.status ?? "-")
                    .padding(.trailing, 12)
                infoTextView(string: detailInfo.airDate ?? "-")
            }
        case .episode:
            if let episode = detailInfo.episode {
                infoTextView(string: "\(episode)회차")
            } else {
                Text("-")
            }
        case .ageRating:
            infoTextView(string: "\(detailInfo.age ?? "-") 이상 시청")
        case .productionCompany:
            if let studios = detailInfo.studios {
                HStack(spacing: 4) {
                    ForEach(studios, id: \.self) { studio in
                        Button {
                            DLog("제작사 탭탭 - \(studio.name)")
                        } label: {
                            Text(studio.name ?? "--")
                                .customFontStyle(size: 14, color: .anipickSecondary)
                                .underline(true, color: .anipickSecondary)
                        }
                    }
                }
            }

        }
    }
    
    private func infoTextView(string: String) -> some View {
        Text(string)
            .customFontStyle(size: 14, color: .gray8)
    }
    
    private func animationFinishedTag(title: String) -> some View {
        Text(title)
            .customFontStyle(size: 14, color: .anipickBlack)
            .padding(.vertical, 7)
            .padding(.horizontal, 16)
            .background(.gray5)
            .cornerRadius(32)
    }
    
    private func sectionCategoryButton(title: String, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Text(title)
                    .customFontStyle(size: 18, color: .anipickBlack, weight: .black)
                
                Spacer()
                Image("chevron-right")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.gray6)
                
            }
        }
    }
    
    private func animationCell(title: String, subtitle: String) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(height: 162)

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(title)
               // .frame(width: 128, height: 45)
                .customFontStyle(size: 12, color: .anipickBlack)
                .lineLimit(2)
                .padding(.top, 6)
            
            if subtitle.isEmpty == false {
                Text(subtitle)
                    .customFontStyle(size: 12, color: .gray8)
            }
        }
    }
    
}
