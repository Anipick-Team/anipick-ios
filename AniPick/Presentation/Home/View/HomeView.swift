//
//  HomeView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct HomeView: View {
    @State private var nickName: String = "띵똥띵똥"
    @State private var recentAnimationName: String = "던전밥"
    
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
            
            Spacer().frame(height: 32)
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)
                        
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("실시간 인기 애니메이션")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.anipickBlack)
                        
                        Spacer()
                        
                        Button {
                            print("실시간 인기 애니메이션 탭탭")
                        } label: {
                            Image(.chevronLeftGray)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 16)

                    ScrollView(.horizontal) {
                        HStack(spacing: 0) {
                            ForEach(0..<5) { _ in
                                self.animationCellWithRakingLabel()
                                    .padding(.trailing, 12)
                            }
                        }
                        .padding(.horizontal, 20)
                       
                    }
                }
                .padding(.top, 36)
              
                
                sectionDivider()
                
                
                self.sectionView(title: "오늘의 추천작, \(nickName)님의\n취향에 맞춰 준비했어요!")
                    .padding(.bottom, 24)
                
                VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text("최근 리뷰")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.anipickBlack)
                            
                            Spacer()
                            
                            Button {
                                print("최근 리뷰 탭탭")
                            } label: {
                                Image(.chevronLeftGray)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: 0) {
                            ForEach(0..<5) { _ in
                                self.recentReviewCell()
                                    .padding(.trailing, 12)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.gray7)
                
                Spacer().frame(height: 28)
                
                // TODO: 얘가 기본 default값 UI
                self.sectionView(title: "25년도 3분기 방영예정")
                
                sectionDivider()
                
                // TODO: 닉네임 글자수가 너무 길 때, 닉네임을 말줄임 하는 것으로 viewModel에서 작업
                self.sectionView(title: "최근 찾아보신 \(recentAnimationName)과\n비슷한 작품이에요!")
  
                sectionDivider()
                
                self.sectionView(title: "공개 예정")
                
              
            }
           
          
        }
       

        
    }
    
    private func sectionView(title: String) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.anipickBlack)
                
                Spacer()
                
                Button {
                    print("\(title) 탭탭")
                } label: {
                    Image(.chevronLeftGray)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16) 
            
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(0..<5) { _ in
                        self.animationCell()
                            .padding(.trailing, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
         
        }
    }
    
    private func sectionDivider() -> some View {
        return VStack(spacing: 0) {
            Spacer().frame(height: 52)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 8)
                .background(.gray7)
            
            Spacer().frame(height: 28)
        }
        .ignoresSafeArea()
    }
    
    private func recentReviewCell() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("그대들은 어떻게 살 것인가")
                    .font(.system(size: 12))
                    .padding(.bottom, 7)
                
                Text("이런 애니메이션 굉장히 오랜만에 보는데 생각보다 취향에 맞아서 좋아요")
                    .frame(width: 197)
                    .lineLimit(2)
                    .font(.system(size: 16))
                    .padding(.bottom, 17)
                
                HStack(spacing: 0) {
                    Text(nickName)
                    
                    Rectangle()
                        .frame(width: 1, height: 10)
                        .padding(.horizontal, 8)
                    
                    Text("2025.04.09")
                }
                .font(.system(size: 12))
                
            }
            .foregroundStyle(.anipickBlack)
            .frame(width: 197, height: 112)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.white)
            .cornerRadius(8)
        }
    }
    
    private func animationCellWithRakingLabel() -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(width: 128, height: 174)
                
                // 초록색 배경의 숫자 뱃지
                ZStack {
                    Rectangle()
                        .foregroundColor(Color.green)
                        .frame(width: 36, height: 36)
                    
                    Text("1")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .black))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("착각하는 공방주 영풍파티의 전 잡어쩌구어쩌구")
                .foregroundStyle(.anipickBlack)
                .frame(width: 128, height: 45)
                .font(.system(size: 16))
                .lineLimit(2)
                .padding(.top, 6)
        }
    }
    
    private func animationCell() -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(width: 128, height: 174)

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("착각하는 공방주 영풍파티의 전 잡어쩌구어쩌구")
                .foregroundStyle(.anipickBlack)
                .frame(width: 128, height: 45)
                .font(.system(size: 16))
                .lineLimit(2)
                .padding(.top, 6)
        }
    }
}


#Preview {
    HomeView()
}
