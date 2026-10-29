import DesignSystem
import MVICore
import SwiftUI
import UIKit

/// 레거시 `ForgetPasswordView`와 같은 배치
struct FindPasswordView: View {
    @State private var store: Store<FindPasswordReducer>

    init(state: FindPasswordReducer.State, reducer: FindPasswordReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 64)

            VStack(alignment: .leading) {
                Text("비밀번호 찾기")
                    .textStyle(size: 24, color: .anipickBlack, weight: .semibold)
                    .padding(.bottom, 4)
                    .padding(.bottom, 4)

                Text("회원 서비스 사용을 위해 비밀번호를 찾아주세요.")
                    .textStyle(size: 14, color: .gray8)
            }

            Spacer().frame(height: 64)

            Text("이메일")
                .textStyle(size: 18, color: .anipickBlack, weight: .semibold)
                .padding(.bottom, 12)

            HStack(spacing: 0) {
                TextField(
                    "",
                    text: Binding(
                        get: { store.state.email },
                        set: { store.send(.emailChanged($0)) }
                    ),
                    prompt: Text("이메일을 입력해주세요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textGray)
                )
                .autocapitalization(.none)
                .padding(16)
                .foregroundColor(.anipickBlack)
                .background(.textFieldBackground)
                .cornerRadius(8)

                Button {
                    store.send(.sendTapped)
                } label: {
                    Text(store.state.sendButtonTitle)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .frame(width: 120, height: 50)
                        .background(store.state.isSendEnabled ? Color.anipickPrimary : Color.gray)
                        .cornerRadius(8)
                        .padding(.leading, 12)
                }
                .disabled(!store.state.isSendEnabled)
            }

            Text(store.state.emailGuide)
                .textStyle(size: 14, color: .point)
                .padding(.top, 12)
                .padding(.leading, 2)

            Spacer().frame(height: 40)

            ZStack {
                codeField()
            }

            Text(store.state.codeGuide)
                .textStyle(size: 14, color: .point)
                .padding(.top, 12)
                .padding(.leading, 2)

            Spacer().frame(height: 40)

            Spacer()

            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)
                .padding(.bottom, 32)

            PrimaryButton("다음", isEnabled: store.state.isNextEnabled) {
                store.send(.nextTapped)
            }
            .padding(.bottom, 16)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(.chevronLeft)
                        .foregroundColor(.black)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .background(Color.white)
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    /// 레거시 `TextFieldComponents(enableTimer: true)`: 오른쪽에 남은 시간
    private func codeField() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Text("인증번호")
                .textStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)

            ZStack {
                TextField(
                    "",
                    text: Binding(
                        get: { store.state.code },
                        set: { store.send(.codeChanged($0)) }
                    ),
                    prompt: Text("인증번호를 입력해주세요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textGray)
                )
                .autocapitalization(.none)
                .foregroundColor(.anipickBlack)
                .padding(16)
                .background(.textFieldBackground)
                .cornerRadius(8)

                HStack {
                    Spacer()
                    Text(store.state.timerText)
                        .textStyle(size: 16, color: .point)
                        .padding(.trailing, 15)
                }
            }
        }
    }
}

/// 레거시 `NewPasswordView`와 같은 배치
struct ResetPasswordView: View {
    @State private var store: Store<ResetPasswordReducer>

    init(state: ResetPasswordReducer.State, reducer: ResetPasswordReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 28)

            VStack(alignment: .leading) {
                Text("비밀번호 찾기")
                    .textStyle(size: 24, color: .anipickBlack, weight: .semibold)
                    .padding(.bottom, 4)

                Text("회원 서비스 이용을 위해 비밀번호를 찾아주세요.")
                    .textStyle(size: 14, color: .textGray)
            }

            Spacer().frame(height: 64)

            PasswordInputField(
                text: Binding(
                    get: { store.state.newPassword },
                    set: { store.send(.newPasswordChanged($0)) }
                ),
                isVisible: store.state.isNewPasswordVisible,
                disablesAutocapitalization: true
            ) {
                store.send(.newPasswordVisibilityTapped)
            }

            Text("8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해주세요.")
                .textStyle(size: 12, color: .gray8)
                .padding(.top, 8)
                .padding(.horizontal, 4)

            Spacer().frame(height: 40)

            PasswordInputField(
                text: Binding(
                    get: { store.state.confirmation },
                    set: { store.send(.confirmationChanged($0)) }
                ),
                isVisible: store.state.isConfirmationVisible,
                placeholder: "새 비밀번호를 다시 한 번 입력해주세요",
                disablesAutocapitalization: true
            ) {
                store.send(.confirmationVisibilityTapped)
            }

            Text(store.state.confirmationGuide)
                .textStyle(size: 14, color: .point)
                .padding(.top, 12)
                .padding(.leading, 2)

            Spacer()

            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)

            Spacer().frame(height: 32)

            PrimaryButton("비밀번호 변경 완료", isEnabled: store.state.isSubmitEnabled) {
                store.send(.submitTapped)
            }
            .padding(.bottom, 16)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(.chevronLeft)
                        .foregroundColor(.black)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .background(Color.white)
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
