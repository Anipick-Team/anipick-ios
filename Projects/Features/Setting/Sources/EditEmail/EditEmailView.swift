import DesignSystem
import MVICore
import SwiftUI
import UIKit

/// 레거시 `EditEmailView`와 같은 배치
struct EditEmailView: View {
    @State private var store: Store<EditEmailReducer>
    @State private var isPasswordVisible = false

    init(state: EditEmailReducer.State, reducer: EditEmailReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)

            BackNavigationBar(title: "이메일 변경") {
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

            Text("기존 이메일")
                .textStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)

            Text(store.state.currentEmail)
                .textStyle(size: 16, color: .anipickBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 20)
                .padding(16)
                .background(Color.gray5)
                .cornerRadius(8)
                .multilineTextAlignment(.leading)

            Spacer().frame(height: 32)

            LabeledTextField(
                title: "새 이메일",
                placeholder: "새 이메일 입력",
                text: Binding(
                    get: { store.state.newEmail },
                    set: { store.send(.newEmailChanged($0)) }
                )
            )
            .padding(.bottom, 12)

            if let emailError = store.state.emailError {
                Text(emailError)
                    .textStyle(size: 14, color: .point, weight: .semibold)
                    .padding(.bottom, 30)
            } else {
                Spacer().frame(height: 30)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("비밀번호")
                        .textStyle(size: 18, color: .anipickBlack, weight: .bold)
                        .padding(.bottom, 12)
                    Spacer()
                }

                passwordField
            }
            .padding(.bottom, 12)

            if store.state.isPasswordMismatch {
                Text("비밀번호가 일치하지 않습니다.")
                    .textStyle(size: 14, color: .point, weight: .semibold)
            }

            Spacer().frame(height: 30)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("•")
                        .padding(.trailing, 10)
                    Text("반드시 본인 명의의 이메일을 입력해주세요.")
                }

                HStack(spacing: 0) {
                    Text("•")
                        .padding(.trailing, 10)
                    Text("본 이메일은 계정 분실 시 아이디 및 비밀번호 찾기, 개인정보 관련 주요 공지사항 안내 등에 사용됩니다.")
                }
            }
            .textStyle(size: 14, color: .gray8)
            .multilineTextAlignment(.leading)

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
        .popup(isPresented: store.state.isCompletionPresented) {
            ConfirmPopup(
                title: "이메일 변경이 완료되었어요.",
                message: "변경된 이메일로 다시 로그인해 주세요.",
                cancelTitle: nil,
                confirmTitle: "확인"
            ) {
                store.send(.completionConfirmed)
            }
        }
    }

    /// 레거시처럼 `autocapitalization(.none)`이 없다 (E5)
    private var passwordField: some View {
        let text = Binding(
            get: { store.state.password },
            set: { store.send(.passwordChanged($0)) }
        )
        let prompt = Text("비밀번호를 입력해주세요")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.textGray)
        return ZStack {
            Group {
                if isPasswordVisible {
                    TextField("", text: text, prompt: prompt)
                } else {
                    SecureField("", text: text, prompt: prompt)
                }
            }
            .foregroundColor(.anipickBlack)
            .padding(16)
            .background(.textFieldBackground)
            .cornerRadius(8)

            HStack {
                Spacer()

                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(isPasswordVisible ? .eyeVisibleIcons : .eyeUnvisibleIcons)
                        .padding(.trailing, 15)
                }
            }
        }
    }
}
