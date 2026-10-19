//
//  CommunityNotCreatedPopupView.swift
//  AniPick
//

import SwiftUI

struct CommunityNotCreatedPopupView: View {
    var animeTitle: String
    var cancelAction: () -> Void
    var inquiryAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("알림")
                    .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 8)

                Text("'\(animeTitle)'의 커뮤니티는 아직 생성되지 않았습니다.\n커뮤니티 생성을 원하실 경우 문의해 주세요.")
                    .customFontStyle(size: 14, color: .settingSubTitle)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 37)

                HStack {
                    Button {
                        cancelAction()
                    } label: {
                        Text("닫기")
                            .customFontStyle(size: 16, color: .textGray)
                            .frame(maxWidth: .infinity)
                    }

                    Divider()

                    Button {
                        inquiryAction()
                    } label: {
                        Text("문의하기")
                            .customFontStyle(size: 16, color: .anipickPrimary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 22)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .frame(maxWidth: 300)
        }
    }
}

#Preview {
    CommunityNotCreatedPopupView(animeTitle: "약사의 혼잣말 3기 단편 애니메이션") {
        DLog("cancel")
    } inquiryAction: {
        DLog("inquiry")
    }
}
