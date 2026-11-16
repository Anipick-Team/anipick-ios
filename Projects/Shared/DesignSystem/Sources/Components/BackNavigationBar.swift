import SwiftUI

/// 왼쪽 뒤로 버튼 + 가운데 제목. 레거시 `NavigationBackButtonView`와 같은 모양이다.
public struct BackNavigationBar: View {
    private let title: String
    private let onBack: () -> Void

    public init(title: String, onBack: @escaping () -> Void) {
        self.title = title
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 0) {
                Button {
                    onBack()
                } label: {
                    Image(.chevronLeft)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding(.leading, 20)
                Spacer()
            }

            Spacer()

            Text(title)
                .textStyle(size: 18, color: .anipickBlack, weight: .black)

            Spacer()
        }
    }
}
