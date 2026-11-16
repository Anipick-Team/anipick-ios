import SwiftUI

/// 제목 + 입력란. 레거시 `TextFieldComponents`의 일반 입력 모양이다.
/// (비밀번호 보기 아이콘·타이머는 필요한 화면을 이관할 때 추가한다)
public struct LabeledTextField: View {
    private let title: String
    private let placeholder: String
    @Binding private var text: String

    public init(title: String, placeholder: String, text: Binding<String>) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .textStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textGray)
            )
            .autocapitalization(.none)
            .foregroundColor(.anipickBlack)
            .padding(16)
            .background(.textFieldBackground)
            .cornerRadius(8)
        }
    }
}
