import DesignSystem
import MVICore
import SwiftUI
import UIKit

/// 레거시 `EmailLoginView`와 같은 배치
struct EmailLoginView: View {
    @State private var store: Store<EmailLoginReducer>

    init(state: EmailLoginReducer.State, reducer: EmailLoginReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                    .frame(height: 28)

                VStack(alignment: .leading) {
                    Text("이메일 로그인")
                        .textStyle(size: 24, color: .anipickBlack, weight: .semibold)
                        .padding(.bottom, 4)

                    Text("회원 서비스 이용을 위해 로그인 해주세요.")
                        .textStyle(size: 14, color: .textGray)
                }

                Spacer().frame(height: 64)

                LabeledTextField(
                    title: "이메일",
                    placeholder: "이메일을 입력해주세요",
                    text: Binding(
                        get: { store.state.email },
                        set: { store.send(.emailChanged($0)) }
                    )
                )
                .autocapitalization(.none)

                Text(store.state.emailGuide)
                    .textStyle(size: 14, color: .point)

                Spacer().frame(height: 40)

                Text("비밀번호")
                    .textStyle(size: 18, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 12)

                passwordField()

                Text(store.state.passwordGuide)
                    .textStyle(size: 14, color: .point)
                    .padding(.top, 6)

                Spacer().frame(height: 40)

                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()

                        Button {
                            store.send(.signupTapped)
                        } label: {
                            Text("회원가입")
                        }

                        Rectangle()
                            .frame(width: 1, height: 15)
                            .padding(.horizontal, 20)

                        Button {
                            store.send(.findPasswordTapped)
                        } label: {
                            Text("비밀번호 찾기")
                        }

                        Spacer()
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(.textGray)
                }

                HStack(spacing: 0) {
                    Spacer()
                    Text(store.state.commonGuide)
                        .textStyle(size: 14, color: .point)
                    Spacer()
                }
                .padding(.vertical, 16)

                Spacer()

                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundStyle(.gray6)
                    .padding(.horizontal, -20)

                Spacer().frame(height: 32)

                PrimaryButton("로그인", isEnabled: store.state.isLoginEnabled) {
                    store.send(.loginTapped)
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

            if store.state.isWithdrawnPopupPresented {
                WithdrawnUserPopup {
                    store.send(.withdrawnPopupClosed)
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func passwordField() -> some View {
        let text = Binding(
            get: { store.state.password },
            set: { store.send(.passwordChanged($0)) }
        )
        let prompt = Text("비밀번호를 입력해주세요")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.textGray)
        return ZStack {
            if store.state.isPasswordVisible {
                TextField("", text: text, prompt: prompt)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
            } else {
                SecureField("", text: text, prompt: prompt)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
            }

            HStack {
                Spacer()

                Button {
                    store.send(.passwordVisibilityTapped)
                } label: {
                    Image(store.state.isPasswordVisible ? .eyeVisibleIcons : .eyeUnvisibleIcons)
                        .padding(.trailing, 15)
                }
            }
        }
    }
}

/// 레거시 `WithdrawlUserPopupView`
struct WithdrawnUserPopup: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("탈퇴된 계정입니다.")
                    .textStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 4)

                Text("자세한 사항은 고객센터로 문의해 주세요.")
                    .textStyle(size: 14, color: .settingSubTitle)

                Text("teamanipick@gmail.com")
                    .textStyle(size: 14, color: .settingSubTitle)
                    .textSelection(.disabled)

                Spacer().frame(height: 37)

                Button {
                    onClose()
                } label: {
                    Text("닫기")
                        .textStyle(size: 16, color: .anipickPrimary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .frame(maxWidth: 300)
        }
    }
}
