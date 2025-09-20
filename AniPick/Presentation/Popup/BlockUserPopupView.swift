//
//  BlockUserPopupView.swift
//  AniPick
//
//  Created by cho on 9/17/25.
//

import SwiftUI

struct BlockUserPopupView: View {
    var cancelAction: () -> Void
    var okAction: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("사용자를 차단하시겠습니까?")
                    .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 8)
                    .padding(.top, 37)
                
                Text("차단한 사용자의 리뷰, 커뮤니티 게시글 및 댓글 등 모든 콘첸츠가 노출되지 않게 됩니다.")
                    .customFontStyle(size: 14, color: .settingSubTitle)
                
                Spacer().frame(height: 40)
                
                HStack {
                    Button {
                        cancelAction()
                    } label: {
                        Text("취소")
                            .customFontStyle(size: 16, color: .textGray)
                            .frame(maxWidth: .infinity)
                    }

                    Divider()

                    Button {
                        okAction()
                    } label: {
                        Text("신고하기")
                            .customFontStyle(size: 16, color: .anipickPrimary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 22)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
}
