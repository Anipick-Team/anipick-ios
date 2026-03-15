//
//  EditEmailPopupView.swift
//  AniPick
//
//  Created by cho on 3/15/26.
//

import SwiftUI

struct EditEmailPopupView: View {
    var okAction: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("이메일 변경이 완료되었어요.")
                    .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 12)

                Text("변경된 이메일로 다시 로그인해 주세요.")
                    .customFontStyle(size: 14, color: .settingSubTitle)
                    
                Spacer().frame(height: 37)
                
                HStack {
                    Button {
                        okAction()
                    } label: {
                        Text("확인")
                            .customFontStyle(size: 16, color: .anipickPrimary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 22)
            }
            .padding(.vertical, 20)
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
}
