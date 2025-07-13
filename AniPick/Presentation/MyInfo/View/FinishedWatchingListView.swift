//
//  FinishedWatchingListView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct FinishedWatchingListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MyInfoViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "다 본 애니") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            // TODO: 총 갯수 가져와서 보여줘야함
            Text("총 12개")
                .customFontStyle(size: 14, color: .gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(0..<12) { _ in
                        animationCell()
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(.chevronLeft)
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    
    
    private func animationCell() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
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
                .padding(.vertical, 6)
            
            HStack(alignment: .center, spacing: 0) {
                Text("내 평가")
                    .customFontStyle(size: 12, color: .gray8)
                    .padding(.trailing, 8)
                
                Image(.fillPickStar)
                    .resizable()
                    .frame(width: 12, height: 12)
                
                Text("2.3")
                    .customFontStyle(size: 14, color: .point)
                
                
            }
            
        }
    }
    
    @ViewBuilder
    private func sectionDivder() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
        
    }
}

#Preview {
    AppDIContainer.makeMyInfoFinishedWatchingView()
}
