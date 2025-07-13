//
//  PreferenceSelectionView.swift
//  AniPick
//
//  Created by cho on 5/3/25.
//

import SwiftUI

struct PreferenceSelectionView: View {
    let genreList: [String] = [  "액션", "모험", "코미디", "드라마", "섹시",
                                 "판타지", "성인", "공포", "마법소녀", "메카",
                                 "음악", "미스터리", "심리", "로맨스", "SF",
                                 "일상", "스포츠", "초자연", "스릴러"]
    var yearList: [String] {
           let currentYear = Calendar.current.component(.year, from: Date())
        return (1993...currentYear).map { String($0) }.reversed()
       }
    let quarterList = ["1분기", "2분기", "3분기", "4분기"]
    
    @State private var selectedList: [String] = []
  
    var currentList: [String] {
           switch selectedTab {
           case .yearQuarter: return yearList
          // case .quarter: return quarterList
           case .genre: return genreList
           }
       }
    
    @State private var selectedTab: FilterTab = .genre
    @State private var searchBarString: String = ""
    @State private var isEnableDoneButton: Bool = false
    @State private var animationCount: Int = 0
    
    @State private var isPresentYearFilter: Bool = false
    
    @State private var sheetHeight: CGFloat = 400
    
    @State private var selectedYear: String = ""
    @State private var selectedQuarter: String = ""
    @State private var selectedGenre: String = ""
    
    @State private var starRating: Int = 0
    @State private var showStarRatingView: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Spacer().frame(height: 34)
            
            Text("좋아하는 애니메이션을 선택하면\n취향에 맞는 작품을 추천할게요")
                .font(.system(size: 20, weight: .semibold))
                .padding(.bottom, 8)
            
            Text("좋아하는 애니메이션을 골라 주세요.")
                .font(.system(size: 14))
                .foregroundStyle(.anipickSecondary)
            
            Spacer().frame(height: 40)
            
            Text("평가한 작품 \(animationCount)")
                .font(.system(size: 14))
                .foregroundStyle(.gray6)
            
            Spacer().frame(height: 16)
            
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .frame(width: 16, height: 16)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                
                TextField(
                    "",
                    text: $searchBarString,
                    prompt: Text("검색")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textGray)
                    )
                .padding(.horizontal, 4)
                
                Spacer()
                
                Button {
                    print("searchBar all clear 버튼")
                } label: {
                    Image(.allClearButton)
                        .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 11)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
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
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray5)
                .padding(.horizontal, -20)
                .padding(.vertical, 20)
            
            
            ScrollView {
                ForEach(0..<10, id: \.self) { value in
                    animationCell(showStarRating: true)
                    // TODO: 각 애니메이션 별 star 표시하도록 적용
                    StarRatingView()
                }
                
            }
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray5)
                .padding(.horizontal, -20)
                .padding(.vertical, 20)
            
            FullWidthButton(isEnable: $isEnableDoneButton, buttonText: "완료") {
                print("완료 버튼 탭탭")
            }
            
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $isPresentYearFilter) {
            filterSelectedHalfModalView()
                .presentationDetents([.height(self.sheetHeight)])
                .onHeightChange { newHeight in
                    self.sheetHeight = newHeight
                }
               
        }
        
    }
    
    enum FilterTab: String, CaseIterable {
        case yearQuarter = "년도/분기"
        case genre = "장르"
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
    
    private func animationCell(showStarRating: Bool) -> some View {
        return Button {
            print("취향 애니메이션 탭탭")
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Rectangle()
                        .foregroundStyle(Color.green)
                        .frame(width: 133, height: 89)
                        .cornerRadius(8)
                        .padding(.trailing, 16)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("애니메이션 제목")
                            .font(.system(size: 14))
                            .foregroundStyle(.textBlack)
                            .padding(.bottom, 4)
                            .padding(.top, 4)
                        
                        Text("이세계")
                            .font(.system(size: 14))
                            .foregroundStyle(.textGray)
                        
                        Spacer()
                        
                        if showStarRating {
                            HStack(spacing: 0) {
                                ForEach(1...5, id: \.self) { starIdx in
                                    Button {
                                        self.starRating = starIdx
                                    } label: {
                                        Image(starIdx <= starRating ? .fillPickStar : .unfillStar)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                    }
                                    .padding(.trailing, 4)
                                    
                                }
                                
                                Text("(\(self.starRating).0)")
                                    .padding(.leading, 8)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.point)
                            }
                            .padding(.bottom, 4)
                        }
                        
                    }
                    
                    
                    Spacer()
                    
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray7, lineWidth: 1)
                    .background(Color.white.cornerRadius(8))
                    .frame(maxWidth: .infinity)
            )
        }
    }
}

#Preview {
    PreferenceSelectionView()
}
