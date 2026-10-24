//
//  SNSSignupPopupView.swift
//  AniPick
//
//  Created by cho on 10/5/25.
//

import SwiftUI

struct SNSSignupPopupView: View {
    var title: String = "SNS로 간편 가입된 계정입니다."
    var message: String = "SNS로 로그인해주세요."
    var confirmTitle: String = "SNS로 로그인"
    var cancelAction: () -> Void
    var okAction: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(title)
                    .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 12)

                Text(message)
                    .customFontStyle(size: 14, color: .settingSubTitle)
                    
                Spacer().frame(height: 37)
                
                HStack {
                    Button {
                        cancelAction()
                    } label: {
                        Text("닫기")
                            .customFontStyle(size: 16, color: .gray6)
                            .frame(maxWidth: .infinity)
                    }

                    Divider()

                    Button {
                        okAction()
                    } label: {
                        Text(confirmTitle)
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
