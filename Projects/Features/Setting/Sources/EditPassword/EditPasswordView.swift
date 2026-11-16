import DesignSystem
import MVICore
import SwiftUI
import UIKit

/// 레거시 `EditPasswordView`와 같은 배치
struct EditPasswordView: View {
    @State private var store: Store<EditPasswordReducer>
    // 보기·가림은 화면 안 상태 (레거시와 같음)
    @State private var isCurrentVisible = false
    @State private var isNewVisible = false
    @State private var isConfirmationVisible = false

    init(state: EditPasswordReducer.State, reducer: EditPasswordReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)

            BackNavigationBar(title: "비밀번호 변경") {
                store.send(.backTapped)
            }
            .padding(.horizontal, -20)

            Spacer().frame(height: 30)

            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .background(.gray5)
                .padding(.horizontal, -20)

            Spacer().frame(height: 36)

            title("현재 비밀번호")

            passwordField(
                text: binding(\.currentPassword) { .currentPasswordChanged($0) },
                prompt: "현재 비밀번호",
                // 레거시: 보기 상태일 때만 16 (P3)
                promptSize: isCurrentVisible ? 16 : 13,
                isVisible: $isCurrentVisible
            )

            if let error = store.state.currentPasswordError, !error.isEmpty {
                Text(error)
                    .textStyle(size: 14, color: .point, weight: .semibold)
                    .padding(.top, 8)
            }

            Spacer().frame(height: 32)

            title("새 비밀번호")

            Image(store.state.isNewPasswordValid ? .check : .uncheck)

            passwordField(
                text: binding(\.newPassword) { .newPasswordChanged($0) },
                prompt: "영문, 숫자, 특수문자 2개 이상 조합, 10자 이상",
                promptSize: 13,
                isVisible: $isNewVisible
            )

            errorText(store.state.newPasswordError)

            Spacer().frame(height: 32)

            title("새 비밀번호 확인")

            Image(store.state.isConfirmationMatched ? .check : .uncheck)

            passwordField(
                text: binding(\.confirmation) { .confirmationChanged($0) },
                prompt: "비밀번호 확인",
                promptSize: 13,
                isVisible: $isConfirmationVisible
            )

            errorText(store.state.confirmationError)

            Spacer()

            Rectangle()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, -40)
                .frame(height: 1)
                .foregroundStyle(Color.gray6)

            Spacer().frame(height: 32)

            PrimaryButton("저장") {
                store.send(.saveTapped)
            }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .background(Color.white)
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func binding(
        _ keyPath: KeyPath<EditPasswordReducer.State, String>,
        intent: @escaping (String) -> EditPasswordReducer.Intent
    ) -> Binding<String> {
        return Binding(
            get: { store.state[keyPath: keyPath] },
            set: { store.send(intent($0)) }
        )
    }

    private func title(_ text: String) -> some View {
        return Text(text)
            .textStyle(size: 18, color: .anipickBlack, weight: .bold)
            .padding(.bottom, 12)
    }

    @ViewBuilder
    private func errorText(_ error: String?) -> some View {
        if let error, !error.isEmpty {
            Text(error)
                .textStyle(size: 12, color: .point, weight: .semibold)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.top, 8)
        }
    }

    private func passwordField(
        text: Binding<String>,
        prompt: String,
        promptSize: CGFloat,
        isVisible: Binding<Bool>
    ) -> some View {
        let promptText = Text(prompt)
            .font(.system(size: promptSize, weight: .medium))
            .foregroundColor(.textGray)
        return ZStack {
            Group {
                if isVisible.wrappedValue {
                    TextField("", text: text, prompt: promptText)
                } else {
                    SecureField("", text: text, prompt: promptText)
                }
            }
            .autocapitalization(.none)
            .foregroundColor(.anipickBlack)
            .padding(16)
            .background(.textFieldBackground)
            .cornerRadius(8)

            HStack {
                Spacer()

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(isVisible.wrappedValue ? .eyeVisibleIcons : .eyeUnvisibleIcons)
                        .padding(.trailing, 15)
                }
            }
        }
    }
}
