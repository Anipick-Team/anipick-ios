//
//  ResearchView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

enum ResearchSelectedTab: String, CaseIterable {
    case yearQuarter = "년도/분기"
    case genre = "장르"
    case releaseType = "타입"
}
struct ResearchView: View {
    @StateObject var viewModel: ResearchViewModel
    let genreList: [String] = [  "액션", "모험", "코미디", "드라마", "섹시",
                                 "판타지", "성인", "공포", "마법소녀", "메카",
                                 "음악", "미스터리", "심리", "로맨스", "SF",
                                 "일상", "스포츠", "초자연", "스릴러"]
    var yearList: [String] {
           let currentYear = Calendar.current.component(.year, from: Date())
        return (1993...currentYear).map { String($0) }.reversed()
       }
    let quarterList: [String] = ["1분기", "2분기", "3분기", "4분기"]
    let releaseTypeList: [String] = ["TVA", "OVA", "극장판"]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    @State private var animationCount: Int = 0
    @State private var selectedTab: ResearchSelectedTab = .yearQuarter
    @State private var isPresentYearFilter: Bool = false
    
    @State private var selectedYear: String = ""
    @State private var selectedQuarter: String = ""
    @State private var selectedGenre: String = ""
    @State private var selectedReleaseType: String = ""
    
    @State private var isAllMatched: Bool = false
    
    @State private var sheetHeight: CGFloat = 400
    
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
            
            // TODO: 년도/분기, 장르, 타입 값 필터링이 들어와야함
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    FilterButton(title: "년도/분기", selectedState: .notSelected) {
                        print("년도/분기 탭탭")
                    }
                        .padding(.trailing, 8)
                    
                    FilterButton(title: "장르", selectedState: .notSelected) {
                        print("장르 탭태")
                    }
                        .padding(.trailing, 8)
                    
                    FilterButton(title: "타입", selectedState: .notSelected) {
                        print("타입 탭탭")
                    }
                        .padding(.trailing, 8)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .background(.gray7)
            
            HStack(spacing: 0) {
                self.selectedKeywordCell(keyword: "2025")
                self.selectedKeywordCell(keyword: "2분기")
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .background(.gray7)
            
            HStack(spacing: 0) {
                Text("총 \(animationCount)개")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray8)
                
                Spacer()
                
                // TODO: 인기순, 평점 순으로 필터링거는 팝업뜨도록 만들어야함
                Button {
                    print("인기순, 평점순 필터링 걸어야함!")
                } label: {
                    Text("인기순")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray8)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(0..<12) { _ in
                        animationCell()
                    }
                }
            }
            .padding(.horizontal, 20)
            .scrollIndicators(.hidden)
        
        }
        .background(Color.white)
        .sheet(isPresented: $isPresentYearFilter) {
            filterKeywordHalfModalView()
                .presentationDetents([.height(self.sheetHeight)])
//                .onHeightChange { newHeight in
//                    self.sheetHeight = newHeight
//                }
               
        }
    }
    
    private func filterKeywordHalfModalView() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Button {
                        self.selectedTab = .yearQuarter
                        self.isPresentYearFilter.toggle()
                    } label: {
                        Text("년도/분기")
                            .padding(.horizontal, 12)
                            .font(.system(size: 16))
                            .foregroundStyle(self.selectedTab == .yearQuarter ? .anipickBlack : .textGray)

                    }
                    
                    Button {
                        self.selectedTab = .genre
                        self.isPresentYearFilter.toggle()
                    } label: {
                        Text("장르")
                            .padding(.horizontal, 12)
                            .font(.system(size: 16))
                            .foregroundStyle(self.selectedTab == .genre ? .anipickBlack : .textGray)
                    }
                    
                    Button {
                        self.selectedTab = .releaseType
                        self.isPresentYearFilter.toggle()
                    } label: {
                        Text("타입")
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
                
            
            HStack(spacing: 0) {
                Spacer()
                
                Text("모든 조건 일치")
                
                Toggle("", isOn: $isAllMatched)
            }
                
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
                } else if self.selectedTab == .genre {
                    ScrollView(showsIndicators: false) {
                        FlowLayout() {
                            ForEach(genreList, id: \.self) { item in
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
                } else {
                    ScrollView(showsIndicators: false) {
                        FlowLayout() {
                            ForEach(releaseTypeList, id: \.self) { item in
                                Button {
                                    print("장르 탭 : \(item)")
                                    self.selectedReleaseType = item
                                } label: {
                                    Text(item)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .foregroundStyle(self.selectedReleaseType == item ? .anipickSecondary : .textBlack)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(self.selectedReleaseType == item ? .anipickSecondary : .gray6)
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
    

    
    
    private func selectedKeywordCell(keyword: String) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(keyword)
                    .foregroundColor(.gray5)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.trailing, 4)
                
                Button {
                    print("keyword 삭제 - \(keyword)")
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 8, height: 8)
                        .foregroundColor(.gray7)
                        
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .background(.anipickPrimary)
            .cornerRadius(32)
        }
        .padding(.trailing, 8)
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
    AppDIContainer.makeResearchView()
}



