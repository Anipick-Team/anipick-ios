import SwiftUI

/// 가로를 채우는 높이 50 버튼. 레거시 `FullWidthButton`과 같은 모양·동작이다.
/// 비활성이어도 눌린다 — 색만 바뀐다 (레거시 동작 보존).
public struct PrimaryButton: View {
    private let title: String
    private let isEnabled: Bool
    private let action: () -> Void

    public init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 16))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isEnabled ? .anipickPrimary : .gray6)
                .cornerRadius(8)
        }
    }
}
