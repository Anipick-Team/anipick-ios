//
//  RecommendedAnimeView.swift
//  AniPick
//
//  Created by cho on 6/23/25.
//

import SwiftUI

struct RecommendedAnimeView: View {
    @Environment(\.dismiss) private var dismiss
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                HStack(alignment: .center, spacing: 0) {
                    Button {
                        DLog("뒤로가기 버튼 탭탭")
                        dismiss()
                    } label: {
                        Image(.chevronLeft)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                
                Spacer()
                
                Text("추천 애니메이션")
                    .customFontStyle(size: 18, color: .anipickBlack)
                
                Spacer()
            }
            
            Spacer().frame(height: 30)
            
            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .background(.gray5)
            
            Spacer().frame(height: 24)
            
            ZStack {
                // 배경
                Rectangle()
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                
                VStack {
                    HStack {
                        Text("최근 찾아보신 던전밥과\n비슷한 작품이에요")
                            .customFontStyle(size: 20, color: .gray5, weight: .bold)
                            .padding(.top, 12)
                            .padding(.leading, 24)
                        Spacer()
                    }
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(.cloud)
                            .padding(.horizontal, 24)
                    }
                }
            }
            .frame(height: 151)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(0..<12) { _ in
                        animationCell()
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 20)
        }
    }
    
    private func animationCell() -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(height: 162)

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("착각하는 공방주 영풍파티의 전 잡어쩌구어쩌구")
               // .frame(width: 128, height: 45)
                .font(.system(size: 14))
                .lineLimit(2)
                .padding(.top, 6)
        }
    }
}

#Preview {
    RecommendedAnimeView()
}
