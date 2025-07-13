//
//  LikePersonListView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//


import SwiftUI

struct LikePersonListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: LikePersonViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "좋아요한 인물") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            // TODO: 총 갯수 가져와서 보여줘야함
            Text("총 14명")
                .customFontStyle(size: 14, color: .gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(0..<12) { _ in
                        // TODO: API 에서 데이터 가져와서 보여줘야함
                        personCell()
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
    
    
    
    private func personCell() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(height: 105)

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("성우이름")
                .font(.system(size: 14))
                .lineLimit(2)
                .padding(.top, 6)
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
    AppDIContainer.makeMyInfoLikePersonView()
}
