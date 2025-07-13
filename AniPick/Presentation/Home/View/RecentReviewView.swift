//
//  RecentReviewView.swift
//  AniPick
//
//  Created by cho on 5/18/25.
//

import SwiftUI

struct RecentReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var menuFrame: CGRect = .zero
    @State private var isShowBlockMenu: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                HStack(alignment: .center, spacing: 0) {
                    Button {
                        DLog("뒤로가기 버튼 탭탭")
                        dismiss()
                    } label: {
                        Image(.chevronLeft)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                
                Spacer()
                
                Text("최근 리뷰")
                    .customFontStyle(size: 18, color: .anipickBlack)
                
                Spacer()
            }
            Spacer().frame(height: 30)

        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global).minY) { newValue in
                                print("🌀 스크롤 offset 변경됨:", newValue)
                                if self.isShowBlockMenu {
                                    self.isShowBlockMenu = false
                                }
                            }
                    }
                    .frame(height: 0)
                    ForEach(0..<5, id: \.self) { idx in
                        RecentReviewCell(id: idx) { id, buttonFrame in
                            self.isShowBlockMenu.toggle()
                            self.menuFrame = buttonFrame
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                    }
                }
                .cornerRadius(8)
            }
            if isShowBlockMenu {
                ReportBlockMenuPopup(isShowBlockMenu: self.$isShowBlockMenu)
                    .position(x: UIScreen.main.bounds.width - 70, y: self.menuFrame.minY + 20)
                    .zIndex(1000)
            }
        }
        .background(.gray7)
        
            
        }
    }
}

#Preview {
    RecentReviewView()
}
