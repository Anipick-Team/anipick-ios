//
//  ImagePreviewPopupView.swift
//  AniPick
//

import SwiftUI
import Kingfisher

/// 애니 표지·배너 원본 이미지를 보여주는 팝업
struct ImagePreviewPopupView: View {
    let imageURL: URL
    let closeAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: closeAction)

            VStack(spacing: 0) {
                KFImage(imageURL)
                    .placeholder {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 160)
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("원본 이미지")

                Button(action: closeAction) {
                    Text("닫기")
                        .customFontStyle(size: 16, color: .anipickPrimary, weight: .medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
    }
}
