//
//  ReportReviewPopupView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct ReportReviewPopupView: View {
    var cancelAction: () -> Void
    var okAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("리뷰를 신고하시겠습니까?")
                    .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 8)

                Text("신고 시, 리뷰 검토 후 처리됩니다.")
                    .customFontStyle(size: 14, color: .settingSubTitle)

                Spacer().frame(height: 37)
                
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
                        Text("다음")
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
    ReportReviewPopupView {
        DLog("cancel")
    } okAction: {
        DLog("ok")
    }

}
