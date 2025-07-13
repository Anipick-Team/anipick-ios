//
//  EditReviewView.swift
//  AniPick
//
//  Created by cho on 6/23/25.
//

import SwiftUI

struct EditReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                
                Text("리뷰 수정")
                    .customFontStyle(size: 18, color: .anipickBlack)
                
                Spacer()
            }
            
            Spacer().frame(height: 30)
            
            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .background(.gray5)
            
            Spacer().frame(height: 24)
            
            ZStack {
                Rectangle()
                    .foregroundColor(.gray7)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 123)
                    .padding(.horizontal, 20)
            }
            
            
            
            
            
            
        }
    }
}

#Preview {
    EditReviewView()
}
