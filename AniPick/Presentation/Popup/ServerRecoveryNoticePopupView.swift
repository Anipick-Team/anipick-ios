//
//  ServerRecoveryNoticePopupView.swift
//  AniPick
//
//  서버 복구 과정 중 데이터 롤백 및 재가입 안내 (1회성 공지)
//

import SwiftUI

struct ServerRecoveryNoticePopupView: View {
    var closeAction: () -> Void

    private let paragraphs: [String] = [
        "7월 7일 서버 복구 과정에서 데이터가 7월 4일 기준으로 롤백되는 문제가 발생했습니다.",
        "이로 인해 7월 4일 이후에 작성된 리뷰, 평가, 시청 기록 등의 데이터가 복구되지 않았으며, 해당 기간에 가입하신 계정 정보 또한 손실되었습니다.",
        "7월 4일 ~7월 7일 가입하신 회원분들은 번거로우시겠지만 다시 가입을 진행해 주시기 바랍니다.",
        "현재 동일한 문제가 재발하지 않도록 서버 증설 및 시스템 개선 작업을 진행하고 있습니다.",
        "서비스 이용에 큰 불편을 드린 점 진심으로 사과드립니다."
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("서버 복구 과정 중\n데이터 롤백 및 재가입 안내")
                    .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(paragraphs, id: \.self) { text in
                        Text(text)
                            .customFontStyle(size: 14, color: .settingSubTitle)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer().frame(height: 28)

                Divider()

                Button {
                    closeAction()
                } label: {
                    Text("닫기")
                        .customFontStyle(size: 16, color: .gray6)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .frame(maxWidth: 320)
            .padding(.horizontal, 24)
        }
    }
}
