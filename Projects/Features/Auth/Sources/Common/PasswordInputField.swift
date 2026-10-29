import DesignSystem
import SwiftUI

/// 회색 입력란 + 오른쪽 눈 아이콘. 레거시 이메일 로그인·가입 화면이 각각 갖고 있던 같은 모양이다.
struct PasswordInputField: View {
    @Binding var text: String
    let isVisible: Bool
    let onVisibilityTapped: () -> Void

    var body: some View {
        let prompt = Text("비밀번호를 입력해주세요")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.textGray)
        ZStack {
            if isVisible {
                TextField("", text: $text, prompt: prompt)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
            } else {
                SecureField("", text: $text, prompt: prompt)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
            }

            HStack {
                Spacer()

                Button {
                    onVisibilityTapped()
                } label: {
                    Image(isVisible ? .eyeVisibleIcons : .eyeUnvisibleIcons)
                        .padding(.trailing, 15)
                }
            }
        }
    }
}
