//
//  AnimationDetailInfoView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct AnimationDetailInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("다솜 산들림 달볓 비나리 예그리나 아름드리 별빛 도담도담 소록소록 가온해 책방 감사합니다 함초롱하다 비나리 소록소록 사과 도르레 곰다시 아련 아련 감사합니다 미쁘다 미쁘다 우리는 비나리 안녕 컴퓨터 아련 이플 함초롱하다 나비잠 바나나 함초롱하다 달볓 산들림 산들림 컴퓨터 달볓 다솜 여우별 옅구름 바나나 소솜 바나나 별하 로운 옅구름 늘품 가온누리 바람꽃.")
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
                    
                    infoView(value: value)
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
            
            HStack(alignment: .center, spacing: 8) {
                self.animationCell(title: "내가 인기가 없는 건 아무리 생각해도 나아아아아앙", subtitle: "2025년 4분기")
                self.animationCell(title: "내가 인기가 없는 건 아무리 생각해도 나아아아아앙", subtitle: "2025년 4분기")
                self.animationCell(title: "내가 인기가 없는 건 아무리 생각해도 나아아아아앙", subtitle: "2025년 4분기")
            }
            
            
            Spacer().frame(height: 48)
            
            
            self.sectionCategoryButton(title: "함께 볼 만한 작품") {
                DLog("함께 볼만한 작품으로 이동")
            }
            .padding(.bottom, 20)
            
            HStack(alignment: .center, spacing: 8) {
                self.animationCell(title: "애니메이션 제목 제목 제목", subtitle: "")
                self.animationCell(title: "애니메이션 제목 제목 제목", subtitle: "")
                self.animationCell(title: "애니메이션 제목 제목 제목", subtitle: "")
            }
        }
    }
    
    @ViewBuilder
    private func infoView(value: AnimationDetailInfo) -> some View {
        switch value {
        case .type:
            infoTextView(string: "TVA")
        case .gerne:
            HStack(alignment: .center, spacing: 0) {
                GerneTagComponents(title: "로맨스")
                GerneTagComponents(title: "액션")
                GerneTagComponents(title: "SF")
            }
        case .release:
            HStack(alignment: .center, spacing: 0) {
                animationFinishedTag()
                    .padding(.trailing, 12)
                infoTextView(string: "2024년 1분기")
            }
        case .episode:
            infoTextView(string: "14회차")
        case .ageRating:
            infoTextView(string: "15세 이상 시청")
        case .productionCompany:
            Button {
                DLog("제작사 탭탭")
            } label: {
                Text("ufotable")
                    .customFontStyle(size: 14, color: .anipickSecondary)
                    .underline(true, color: .anipickSecondary)
            }
        }
    }
    
    private func infoTextView(string: String) -> some View {
        Text(string)
            .customFontStyle(size: 14, color: .gray8)
    }
    
    private func animationFinishedTag() -> some View {
        Text("방영 종료")
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
