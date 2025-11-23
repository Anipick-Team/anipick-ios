//
//  WithdrawlUserPopupView.swift
//  AniPick
//
//  Created by cho on 11/23/25.
//

import SwiftUI

struct WithdrawlUserPopupView: View {
    var closeAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("탈퇴된 계정입니다.")
                    .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 4)
                

                Text("자세한 사항은 고객센터로 문의해 주세요.")
                    .customFontStyle(size: 14, color: .settingSubTitle)
                
                Text("teamanipick@gmail.com")
                    .customFontStyle(size: 14, color: .settingSubTitle)
                    .textSelection(.disabled)
                
                Spacer().frame(height: 37)
                
                Button {
                    closeAction()
                } label: {
                    Text("닫기")
                        .customFontStyle(size: 16, color: .anipickPrimary)
                        .frame(maxWidth: .infinity)
                }
                
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .frame(maxWidth: 300)
        }
    }
}
