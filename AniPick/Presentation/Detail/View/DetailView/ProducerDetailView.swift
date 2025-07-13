//
//  ProducerDetailView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct ProducerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "제작사이름이름") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            ScrollView {
                ProducerProductView()
                
                self.sectionDivder()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, -40)
                
                ProducerProductView()
                self.sectionDivder()
                    .padding(.horizontal, -20)
                
                ProducerProductView()
            }
            .padding(.horizontal, 20)
        }
    }

    private func ProducerProductView() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 24)
            
            self.yearTag(year: "2025")
                .padding(.bottom, 20)
            
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(0..<5) { _ in
                    // TODO: API 에서 데이터 가져와서 보여줘야함
                    animationCell()
                }
            }
            
            Spacer().frame(height: 32)

        }
        .frame(maxWidth: .infinity)
    }
    
    private func yearTag(year: String) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Text(year)
                .padding(.vertical, 7)
                .padding(.horizontal, 8)
                .customFontStyle(size: 14, color: .anipickBlack)
                .background(Color.gray5)
                .cornerRadius(32)
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
    ProducerDetailView()
}
