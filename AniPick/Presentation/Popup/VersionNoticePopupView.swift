import SwiftUI

struct VersionNoticePopupView: View {
    let title: String
    let content: String
    let url: String?
    let closeAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(title)
                    .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                ScrollView(showsIndicators: false) {
                    Text(content)
                        .customFontStyle(size: 14, color: .settingSubTitle)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)
                }
                .frame(maxHeight: 260)

                if let url, !url.isEmpty, let link = URL(string: url) {
                    Link("자세히 보기", destination: link)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.anipickPrimary)
                        .padding(.top, 16)
                }

                Divider()
                    .padding(.top, 24)

                Button(action: closeAction) {
                    Text("닫기")
                        .customFontStyle(size: 16, color: .gray6)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .frame(maxWidth: 340)
            .padding(.horizontal, 24)
        }
    }
}
