//
//  RecentReviewView.swift
//  AniPick
//
//  Created by cho on 5/18/25.
//

import SwiftUI

struct RecentReviewView: View {
    
    @State private var menuFrame: CGRect = .zero
    @State private var isShowBlockMenu: Bool = false
    
    var body: some View {
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

#Preview {
    RecentReviewView()
}
