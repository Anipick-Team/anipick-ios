//
//  RankingView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI


enum RankingFilter: String {
    case realTime = "실시간"
    case yearQuater = "년도/분기"
    case history = "역대"
}

struct RankingView: View {
    @State private var selectedGenre: String = "미스터리"
    @StateObject var viewModel: RankingViewModel
    
    @State private var isPresentGenreModalView: Bool = false
    @State private var sheetHeight: CGFloat = 300
    @State private var genreList = UserDefaultsManager.shared.getMetaDataForGenres().map { $0.name }
    
    
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
                    filterCell(myFilter: .realTime)
                        .padding(.trailing, 8)
                    
                    filterCell(myFilter: .yearQuater)
                        .padding(.trailing, 8)
                    
                    filterCell(myFilter: .history)
                        .padding(.trailing, 8)
                    
                    Spacer()
                    
                    Button {
                        DLog("장르 선택")
                        self.isPresentGenreModalView.toggle()
                    } label: {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Text(self.viewModel.selectedGenre)
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
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.rankingAnimeList, id: \.self) { item in
                        self.rankingAnimationCell(item: item)
                            .padding(.vertical, 16)
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentItem: item)
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
            
        }
        .background(Color.white)
        .onAppear {
          //  self.viewModel.fetchRankingDataList()
            if viewModel.rankingAnimeList.isEmpty {
                viewModel.fetchFirstPage()
             //   viewModel.resetData()
            }
        }
        .sheet(isPresented: self.$isPresentGenreModalView) {
            self.makeGenreModalView()
                .presentationDetents([.height(self.sheetHeight)])
//                .onHeightChange { newHeight in
//                    self.sheetHeight = newHeight
//                }
        }
    }
    
    private func makeGenreModalView() -> some View {
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                
                Text("장르")
                    .customFontStyle(size: 16, color: .anipickBlack)
                    .padding(.horizontal, 12)
                
                Spacer()
                
                Button {
                    print("닫기 탭탭")
                    self.isPresentGenreModalView.toggle()
                } label: {
                    Image(.xButton)
                        .frame(width: 12, height: 12)
                }
                
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
            
            ScrollView {
                FlowLayout() {
                    ForEach(self.genreList, id: \.self) { item in
                        Button {
                            DLog("장르 탭 : \(item)")
                            self.viewModel.selectedGenre = item
//                            self.viewModel.selectedGenre(name: item)
//                            self.viewModel.selectedGenre = item
                        } label: {
                            Text(item)
                                .font(.system(size: 14))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .foregroundStyle(self.viewModel.selectedGenre == item ? .anipickSecondary : .textBlack)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(self.viewModel.selectedGenre == item ? .anipickSecondary : .gray6)
                                )
                        }
                        
                    }
                }
            }
            .padding(20)
            
            HStack(spacing: 0) {
                
                Spacer()
                
                Button {
                    DLog("초기화버튼 탭")
                    self.viewModel.selectedGenre = "장르"
                    self.viewModel.resetData()
                } label: {
                    Text("초기화")
                        .font(.system(size: 14))
                        .foregroundStyle(.textGray)
                }
                
                Spacer().frame(width: 16)
                
                Button {
                    DLog("완료버튼")
                    self.isPresentGenreModalView.toggle()
                    self.viewModel.resetData()
                } label: {
                    Text("완료")
                        .frame(width: 60, height: 30)
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                        .background(.anipickPrimary)
                        .cornerRadius(4)
                }
            }
            .padding(.trailing, 20)
        }
        .background(.white)
        .frame(height: self.sheetHeight)
    }
    
    private func rankingAnimationCell(item: RankedAnime) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("\(item.rank ?? 0)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.anipickBlack)
                        .padding(.bottom, 8)
                    
                    HStack(alignment: .center, spacing: 0) {
                        // TODO: 오는 데이터값에 따라 색상과 trianle 변경
//                        Image(.upTrianglePink)
//                        
//                        Text("12")
//                            .font(.system(size: 14))
//                            .foregroundStyle(.point)
                    }
                }
                .padding(.trailing, 15)
                
                ZStack(alignment: .topLeading) {
                    if let url = item.coverImageUrl {
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .empty:
                                // 로딩 중 placeholder
                                Image(.animeThumbnail)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 128, height: 182)
                                    .clipped()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 128, height: 182)
                                    .clipped()
                                
                            case .failure:
                                // 실패 시 fallback
                                Image(.animeThumbnail)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 128, height: 182)
                                    .clipped()
                                
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
//                Rectangle()
//                    .frame(width: 128, height: 182)
//                    .foregroundStyle(.gray)
//                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.title ?? "-")
                        .lineLimit(2)
                        .font(.system(size: 16))
                        .foregroundStyle(.anipickBlack)
                    
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(item.genres ?? [], id: \.self) { item in
                            self.gerneCell(title: item)
                                .padding(.trailing, 4)
                        }
                       
//                        self.gerneCell(title: "액션")
//                            .padding(.trailing, 4)
//                        self.gerneCell(title: "SF")
//                            .padding(.trailing, 4)
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
    
    private func filterCell(myFilter: RankingFilter) -> some View {
        return Button {
            self.viewModel.isSelectedFilter = myFilter
            viewModel.fetchFirstPage()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(myFilter.rawValue)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .customFontStyle(size: 13, color: self.viewModel.isSelectedFilter == myFilter ? .gray5 : .white)
                    .background(self.viewModel.isSelectedFilter == myFilter ? .anipickPrimary : .gray6)
                    .cornerRadius(32)
            }
        }
    }
}

#Preview {
    AppDIContainer.makeRakingView()
}
