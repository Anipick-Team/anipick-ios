import DesignSystem
import SwiftUI

/// 마이페이지 목록 화면 공통 틀: 뒤로·제목, 구분 띠, "총 N개"
struct ListScaffold<Content: View>: View {
    let title: String
    let countText: String
    let onBack: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackNavigationBar(title: title) {
                onBack()
            }
            .padding(.horizontal, -20)

            Spacer().frame(height: 30)

            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .background(.gray5)
                .padding(.horizontal, -20)

            Spacer().frame(height: 20)

            Text(countText)
                .textStyle(size: 14, color: .gray8)
                .padding(.bottom, 20)

            content()
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 20)
        .background(Color.white)
    }

    static var columns: [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    }
}
