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
    @StateObject var viewModel: RankingViewModel
    var genres: [String] = []
    private let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 4)
    ]
    @State private var isPresentGenreModalView: Bool = false
    @State private var isPresentYearSeasonModalView: Bool = false
    
    @State private var selectedTmpYear: String = ""
    @State private var selectedTmpSeason: String = ""
    
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
                    DLog("searchButton Tapped")
                    self.viewModel.moveToSearchView()
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
            
            
            ScrollView(showsIndicators: false) {
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
            if viewModel.rankingAnimeList.isEmpty {
                viewModel.fetchFirstPage()
            }
        }
        .sheet(isPresented: self.$isPresentGenreModalView) {
            self.makeGenreModalView()
                .presentationDetents([.height(self.sheetHeight)])
        }
        .sheet(isPresented: self.$isPresentYearSeasonModalView) {
            self.makeYearSeaonModalView()
                .presentationDetents([.height(self.sheetHeight)])
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
            
            ScrollView(showsIndicators: false) {
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
                    self.viewModel.fetchFirstPage()
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
    
    private func makeYearSeaonModalView() -> some View {
        let yearList = UserDefaultsManager.shared.getMetaDataForSeasonYear().map { String($0) }
        let quarterList = ["전체 분기", "1", "2", "3", "4"]
        
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("년도/분기")
                    .customFontStyle(size: 16, color: .anipickBlack)
                    .padding(.horizontal, 12)
                
                Spacer()
                
                Button {
                    print("닫기 탭탭")
                    self.isPresentYearSeasonModalView.toggle()
                } label: {
                    Image(.xButton)
                        .frame(width: 12, height: 12)
                }
                
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
            
            HStack(spacing: 0) {
                Picker("", selection: self.$selectedTmpYear) {
                    ForEach(yearList, id: \.self) {
                        Text($0)
                            .customFontStyle(size: 18, color: .anipickSecondary)
                    }
                }
                .pickerStyle(.wheel)
                
                Picker("", selection: self.$selectedTmpSeason) {
                    ForEach(quarterList, id: \.self) {
                        Text("\($0)")
                            .customFontStyle(size: 18, color: .anipickSecondary)
                    }
                }
                .pickerStyle(.wheel)
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                Spacer()
                
                Button {
                    DLog("초기화버튼 탭")
                    self.viewModel.resetData()
                } label: {
                    Text("초기화")
                        .font(.system(size: 14))
                        .foregroundStyle(.textGray)
                }
                
                Spacer().frame(width: 16)
                
                Button {
                    DLog("완료버튼")
                    self.viewModel.selectedYear = self.selectedTmpYear
                    self.viewModel.selectedSeason = self.selectedTmpSeason
                    self.isPresentYearSeasonModalView.toggle()
                    self.viewModel.fetchFirstPage()
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
        .background(Color.white.ignoresSafeArea())
        .frame(height: self.sheetHeight)
    }
    
    private func rankingAnimationCell(item: RankedAnime) -> some View {
        return Button {
            self.viewModel.moveToAnimeDetailView(animeId: item.animeId ?? 0)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
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
                    
                    AnimeImageCommonCell(
                        imageUrl: item.coverImageUrl,
                        width: 128,
                        height: 182
                    )
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title ?? "-")
                            .lineLimit(2)
                            .font(.system(size: 16))
                            .foregroundStyle(.anipickBlack)
                            .multilineTextAlignment(.leading)
                        
                        FlowCellLayout(spacing: 4) {
                      //  LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
                            ForEach(item.genres ?? [], id: \.self) { genre in
                                gerneCell(title: genre)
                                    .padding(.trailing, 4)
                            }
                        }
//                        HStack(alignment: .center, spacing: 0) {
//                            ForEach(item.genres ?? [], id: \.self) { item in
//                                self.gerneCell(title: item)
//                                    .padding(.trailing, 4)
//                            }
//                        }
                        .padding(.trailing, 4)
                        .padding(.vertical, 4)
                        
                    }
                    .padding(.horizontal, 16)
                }
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
                .lineLimit(1)
        }
    }
    
    private func filterCell(myFilter: RankingFilter) -> some View {
        return Button {
            self.viewModel.isSelectedFilter = myFilter
            if myFilter == .yearQuater {
                self.isPresentYearSeasonModalView.toggle()
            }
            viewModel.fetchFirstPage()
            self.viewModel.selectedYear = ""
            self.viewModel.selectedSeason = ""
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                if self.viewModel.isSelectedFilter == .yearQuater && myFilter == .yearQuater {
                    let year = self.viewModel.selectedYear.isEmpty ? "년도" : self.viewModel.selectedYear
                    let season = self.viewModel.selectedSeason.isEmpty ? "" : self.viewModel.selectedSeason
                    if season == "전체 분기" {
                        Text("\(year)/전체 분기")
                            .padding(.vertical, 7)
                            .padding(.horizontal, 12)
                            .customFontStyle(size: 13, color: self.viewModel.isSelectedFilter == myFilter ? .gray5 : .white)
                            .background(self.viewModel.isSelectedFilter == myFilter ? .anipickPrimary : .gray6)
                            .cornerRadius(32)
                    } else {
                        Text("\(year)/\(season)분기")
                            .padding(.vertical, 7)
                            .padding(.horizontal, 12)
                            .customFontStyle(size: 13, color: self.viewModel.isSelectedFilter == myFilter ? .gray5 : .white)
                            .background(self.viewModel.isSelectedFilter == myFilter ? .anipickPrimary : .gray6)
                            .cornerRadius(32)
                    }
                } else {
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
}

#Preview {
    AppDIContainer.makeRakingView()
}
