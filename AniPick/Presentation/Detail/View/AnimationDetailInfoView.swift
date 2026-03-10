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
    
    @StateObject var viewModel: AnimationInfoViewModel
    
    @State private var lineLimit: Int? = 3
    
    @State private var collapsedHeight: CGFloat = 0   // 3줄 기준 높이
    @State private var fullHeight: CGFloat = 0        // 전체 높이

    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let description = detailInfo.description ?? "--"
            Text(description)
                .customFontStyle(size: 14, color: .anipickBlack)
                .lineLimit(self.lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
                .overlay(
                    VStack {
                        // collapsed(3줄) 높이 측정용
                        Text(description)
                            .customFontStyle(size: 14, color: .anipickBlack)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear { collapsedHeight = geo.size.height }
                                        .onChange(of: geo.size.height) { collapsedHeight = $0 }
                                }
                            )
                            .hidden() // 레이아웃 제외됨

                        // full(전체줄) 높이 측정용
                        Text(description)
                            .customFontStyle(size: 14, color: .anipickBlack)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear { fullHeight = geo.size.height }
                                        .onChange(of: geo.size.height) { fullHeight = $0 }
                                }
                            )
                            .hidden() // 레이아웃 제외됨
                    }
                )

            if fullHeight > collapsedHeight + 1 {
                HStack(alignment: .center, spacing: 0) {
                    Button {
                        DLog("더보기 버튼 탭탭")
                        if self.lineLimit == 3 {
                            self.lineLimit = nil
                        } else {
                            self.lineLimit = 3
                        }
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Text("더보기")
                                .font(.system(size: 14))
                                .foregroundStyle(.anipickPrimary)
                                .padding(.trailing, 4)

                            Image(.chevronDownPrimary)
                                .rotationEffect(self.lineLimit == 3 ? .degrees(0) : .degrees(180))
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
            
            ForEach(AnimationDetailInfo.allCases, id: \.self) { value in
                HStack(alignment: .top, spacing: 0) {
                    Text(value.title)
                        .customFontStyle(size: 14, color: .anipickBlack)
                        .padding(.vertical, 10)
                    
                    Spacer()
                    
                    infoView(value: value, detailInfo: detailInfo)
                }
            }
            
            Spacer().frame(height: 60)
            
            self.sectionCategoryButton(title: "캐릭터/성우진") {
                self.viewModel.moveToVoiceActorDetailView(animeId: detailInfo.animeId)
                DLog("캐릭터 성우진 상세로 이동")
            }
            .padding(.bottom, 20)
            
            // TODO: 캐릭터, 성우진만 넣으면 UI가 깨짐 확인 필요 및 UI 수정
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: 8) {
                    ForEach(viewModel.characterInfoList, id: \.self) { item in
                        CharacterAndVoiceActorCellView(
                            characterImageUrl: item.character?.imageUrl ?? "",
                            charactreName: item.character?.name ?? "",
                            voiceActorImageUrl: item.voiceActor?.imageUrl ?? "",
                            voiceActorName: item.voiceActor?.name ?? ""
                        )
                        .onTapGesture {
                            self.viewModel.moveToVoiceActorDetailView(personId: item.voiceActor?.id ?? 0)
                        }
                    }
                }
                .padding(.horizontal, 12)
                
            }
            .frame(width: UIScreen.main.bounds.width - 20)   // ★ 가로 영역 고정!
            .contentShape(Rectangle())                  // 터치영역 명확화
            .clipped()                                  // 부모 확장 방지
            .scrollDisabled(false)
            .padding(.bottom, 20)
            
            
            if viewModel.seriesInfoList.isEmpty == false {
            self.sectionCategoryButton(title: "관련 작품") {
                DLog("관련 작품으로 이동")
                self.viewModel.moveToSeriesDetailView(animeId: detailInfo.animeId, animeTitle: detailInfo.title ?? "-")
            }
            .padding(.bottom, 20)
            
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .center, spacing: 8) {
                        ForEach(viewModel.seriesInfoList, id: \.self) { item in
                            AnimeCommonCellWithTitle(
                                imageUrl: item.coverImageUrl,
                                width: 115,
                                height: 162,
                                title: item.title
                            )
                            .onTapGesture {
                                // TODO: 시리즈 디테일로 이동
                                DLog("해당 시리즈로 이동")
                                self.viewModel.moveToAnimeDetailView(animeId: item.animeId ?? 0)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(width: UIScreen.main.bounds.width - 20)
                .contentShape(Rectangle())
                .clipped()
                .scrollDisabled(false)
                .padding(.bottom, 20)
            
            
            Spacer().frame(height: 48)
                
            }
            
            if viewModel.recommendAnimeList.isEmpty == false {
            self.sectionCategoryButton(title: "함께 볼만한 작품") {
                DLog("함께 볼만한 작품으로 이동")
                self.viewModel.moveToRecommendView(animeId: detailInfo.animeId, animeTitle: detailInfo.title ?? "-")
            }
            .padding(.bottom, 20)
           
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .center, spacing: 8) {
                        ForEach(viewModel.recommendAnimeList, id: \.self) { item in
                            AnimeCommonCellWithTitle(
                                imageUrl: item.coverImageUrl,
                                width: 115,
                                height: 162,
                                title: item.title
                            )
                            .onTapGesture {
                                // TODO: 함께볼만한 작품 디테일로 이동
                                DLog("함께볼만한 작품")
                                self.viewModel.moveToAnimeDetailView(animeId: item.animeId ?? 0)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .contentShape(Rectangle())                  // 터치영역 명확화
                .clipped()                                  // 부모 확장 방지
                .scrollDisabled(false)
                .padding(.bottom, 20)
            }
        }
        .background(Color.white)
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
                FlowCellLayout(spacing: 4, alignment: .trailing) {
                    ForEach(studios, id: \.self) { studio in
                        if let name = studio.name {
                            Button {
                                DLog("제작사 탭탭 - \(String(describing: studio.name)) \(studio.studioId)")
                                self.viewModel.moveToProducerDetailView(studioId: studio.studioId ?? 0)
                            } label: {
                                Text(name)
                                    .customFontStyle(size: 14, color: .anipickSecondary)
                                    .underline(true, color: .anipickSecondary)
                            }
                        }
                    }
                }
                .padding(.top, 10)
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
}
