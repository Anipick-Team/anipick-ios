//
//  ExploreView.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import SwiftUI

struct ExploreView: View {
    @StateObject var viewModel: ExploreViewModel
    @State private var selectedTab: FilterTab = .genre
    @State private var isPresentYearFilter: Bool = false
    @State private var selectedYear: String = ""
    @State private var selectedQuarter: String = ""
    @State private var selectedGenre: String = ""
    @State private var sheetHeight: CGFloat = 400
    var currentList: [String] {
           switch selectedTab {
           case .yearQuarter: return yearList
          // case .quarter: return quarterList
           case .genre: return genreList
           }
       }
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    // TODO: 메타데이터로 교체
    let genreList: [String] = [  "액션", "모험", "코미디", "드라마", "섹시",
                                 "판타지", "성인", "공포", "마법소녀", "메카",
                                 "음악", "미스터리", "심리", "로맨스", "SF",
                                 "일상", "스포츠", "초자연", "스릴러"]
    var yearList: [String] {
           let currentYear = Calendar.current.component(.year, from: Date())
        return (1993...currentYear).map { String($0) }.reversed()
       }
    let quarterList = ["1분기", "2분기", "3분기", "4분기"]
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            
            
            Spacer().frame(height: 16)
            
            HStack(spacing: 0) {
                Button {
                    print("년도 탭탭")
                    self.selectedTab = .yearQuarter
                    self.isPresentYearFilter.toggle()
                } label: {
                    HStack(alignment: .center, spacing: 0) {
                        Text(self.selectedYear.isEmpty ? "년도" : self.selectedYear)
                            .font(.system(size: 16))
                            .foregroundStyle(self.selectedYear.isEmpty ? .textBlack : .anipickSecondary)
                            .padding(.trailing, 10)
                        
                        Image(self.selectedYear.isEmpty ? .chevronDownGray : .chevronDownBlue)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(self.selectedYear.isEmpty ? .gray5 : .anipickSecondary, lineWidth: 1)
                    )
                    .foregroundStyle(.anipickBlack)
                }
                .padding(.trailing, 8)
                
                
                Button {
                    print("분기 탭탭")
                    self.selectedTab = .yearQuarter
                    self.isPresentYearFilter.toggle()
                } label: {
                    HStack(alignment: .center, spacing: 0) {
                        Text(self.selectedQuarter.isEmpty ? "분기" : self.selectedQuarter)
                            .font(.system(size: 16))
                            .foregroundStyle(self.selectedQuarter.isEmpty ? .textBlack : .anipickSecondary)
                            .padding(.trailing, 10)
                        
                        Image(self.selectedQuarter.isEmpty ? .chevronDownGray : .chevronDownBlue)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(self.selectedQuarter.isEmpty ? .gray5 : .anipickSecondary, lineWidth: 1)
                    )
                    .foregroundStyle(.anipickBlack)
                }
                .padding(.trailing, 8)
                
                
                
                Button {
                    print("장르 탭탭")
                    self.selectedTab = .genre
                    self.isPresentYearFilter.toggle()
                } label: {
                    HStack(alignment: .center, spacing: 0) {
                        Text(self.selectedGenre.isEmpty ? "장르" : self.selectedGenre)
                            .font(.system(size: 16))
                            .foregroundStyle(self.selectedGenre.isEmpty ? .textBlack : .anipickSecondary)
                            .padding(.trailing, 10)
                        
                        Image(self.selectedGenre.isEmpty ? .chevronDownGray : .chevronDownBlue)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(self.selectedGenre.isEmpty ? .gray5 : .anipickSecondary, lineWidth: 1)
                    )
                    .foregroundStyle(.anipickBlack)
                }

            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 0) {
                Spacer()
                
                Button {
                    DLog("인기순 탭탭")
                } label: {
                    Text("인기순")
                }
            }
            .padding(.vertical, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(viewModel.exploreItems, id: \.self) { item in
                        // TODO: API 에서 데이터 가져와서 보여줘야함
                        animationCell(item: item)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
      
        .sheet(isPresented: $isPresentYearFilter) {
            filterSelectedHalfModalView()
                .presentationDetents([.height(self.sheetHeight)])
                .onHeightChange { newHeight in
                    self.sheetHeight = newHeight
                }
               
        }
        .onAppear {
            Task {
                await viewModel.getExploreItems(category: .popularity)
            }
        }
      
    }
    
    private func filterSelectedHalfModalView() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    self.selectedTab = .yearQuarter
                } label: {
                    Text("년도/분기")
                        .padding(.horizontal, 12)
                        .font(.system(size: 16))
                        .foregroundStyle(self.selectedTab == .yearQuarter ? .anipickBlack : .textGray)

                }
                
                Button {
                    self.selectedTab = .genre
                } label: {
                    Text("장르")
                        .padding(.horizontal, 12)
                        .font(.system(size: 16))
                        .foregroundStyle(self.selectedTab == .genre ? .anipickBlack : .textGray)
                }
                
                Spacer()
                
                
                Button {
                    print("닫기 탭탭")
                    self.isPresentYearFilter.toggle()
                } label: {
                    Image(.xButton)
                        .frame(width: 12, height: 12)
                }
            }
            .foregroundStyle(.textBlack)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .padding(.horizontal, 20)
            
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray7)
            
            
            if self.selectedTab == .yearQuarter {
                // TODO: wheel picker Custom 하게 구현 -> Color 색상 변경 가능하도록 수정
                HStack(spacing: 0) {
                    Picker("", selection: $selectedYear) {
                        ForEach(yearList, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("", selection: $selectedQuarter) {
                        ForEach(quarterList, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            } else {
                
                ScrollView {
                    FlowLayout() {
                        ForEach(currentList, id: \.self) { item in
                            Button {
                                print("장르 탭 : \(item)")
                                self.selectedGenre = item
                            } label: {
                                Text(item)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(self.selectedGenre == item ? .anipickSecondary : .textBlack)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(self.selectedGenre == item ? .anipickSecondary : .gray6)
                                    )
                            }
                            
                        }
                    }
                }
                .padding(20)
                
            }
            
            
            Spacer()
            
            HStack(spacing: 0) {
                
                Spacer()
                
                Button {
                    print("초기화버튼 탭")
                    self.selectedYear = ""
                    self.selectedGenre = ""
                    self.selectedQuarter = ""
                } label: {
                    Text("초기화")
                        .font(.system(size: 14))
                        .foregroundStyle(.textGray)
                }
                
                Spacer().frame(width: 16)
                
                Button {
                    print("완료버튼")
                    // TODO: 완료버튼을 눌렀을 때, sheet 닫히고 filter에 적용되도록 수정
                    
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
        .padding(.vertical, 20)
    }
    
    private func animationCell(item: Anime) -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                if let url = item.coverImageUrl {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            // 로딩 중 placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                            
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipped()
                            
                        case .failure:
                            Image(systemName: "photo")
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
               // .frame(width: 128, height: 45)
                .font(.system(size: 14))
                .lineLimit(2)
                .padding(.top, 6)
        }
    }
    
    
}

#Preview {
    AppDIContainer.makeExploreView()
}
