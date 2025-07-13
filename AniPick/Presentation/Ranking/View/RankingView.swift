//
//  RankingView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct RankingView: View {
    @State private var selectedGenre: String = "미스터리"
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 상단 로고 및 searchBar
            HStack(spacing: 0) {
                Image(.aniPickLogoGreen)
                    .resizable()
                    .frame(width: 110, height: 22)
                
                Spacer()
                
                Button {
                    print("searchButton Tapped")
                } label: {
                    Image(.searchIconsGray)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .background(.gray5)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 9)
                .background(.gray7)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    // TODO: 셋 중 하나만 선택해야함 -> selectedFilter 생성 후 관리
                    filterCell(title: "실시간")
                        .padding(.trailing, 8)
                    
                    filterCell(title: "년도/분기")
                        .padding(.trailing, 8)
                    
                    filterCell(title: "역대")
                        .padding(.trailing, 8)
                    
                    
                    Spacer()
                    
                    Button {
                        DLog("장르 선택")
                    } label: {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Text(self.selectedGenre)
                                    .customFontStyle(size: 16, color: .anipickSecondary)
                                    .padding(.trailing, 8)
                                
                                Image(.chevronDownBlue)
                                
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.anipickSecondary)
                        )
                    }
                    
                    
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .background(.gray7)
            
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<10) { _ in
                        self.rankingAnimationCell()
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 20)
            }
            
        }
    }
    
    private func rankingAnimationCell() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("01")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.anipickBlack)
                        .padding(.bottom, 8)
                    
                    HStack(alignment: .center, spacing: 0) {
                        // TODO: 오는 데이터값에 따라 색상과 trianle 변경
                        Image(.upTrianglePink)
                        
                        Text("12")
                            .font(.system(size: 14))
                            .foregroundStyle(.point)
                    }
                }
                .padding(.trailing, 15)
                
                Rectangle()
                    .frame(width: 128, height: 182)
                    .foregroundStyle(.gray)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("너를 너무너무너무너무 좋아하는 100명의 그녀 혼자 토벌따라라란")
                        .lineLimit(2)
                        .font(.system(size: 16))
                        .foregroundStyle(.anipickBlack)
                    
                    HStack(alignment: .center, spacing: 0) {
                        self.gerneCell(title: "로맨스")
                            .padding(.trailing, 4)
                        self.gerneCell(title: "액션")
                            .padding(.trailing, 4)
                        self.gerneCell(title: "SF")
                            .padding(.trailing, 4)
//                        ForEach(0..<3) { _ in
//                            self.gerneCell(title: "로맨스")
//                                .padding(.trailing, 4)
//                        }
//                        
                    }
                    .padding(.trailing, 4)
                    .padding(.vertical, 4)
                    
                }
                .padding(.horizontal, 16)
            }
            
         
        }
    }
    
    private func gerneCell(title: String) -> some View {
        return VStack(spacing: 0) {
            Text(title)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .font(.system(size: 12))
                .foregroundStyle(.anipickPrimary)
                .background(.anipickPrimary.opacity(0.1))
                .cornerRadius(8)
        }
    }
    private func filterCell(title: String) -> some View {
        return Button {
            DLog("필터값 변경변경")
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .customFontStyle(size: 13, color: .gray5)
                    .background(.anipickPrimary)
                    .cornerRadius(32)
            }
        }
    }
}

#Preview {
    RankingView()
}
