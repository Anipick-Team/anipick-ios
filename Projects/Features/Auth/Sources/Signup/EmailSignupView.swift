import DesignSystem
import MVICore
import SwiftUI
import UIKit

/// 레거시 `EmailSignupView`와 같은 배치
struct EmailSignupView: View {
    @State private var store: Store<EmailSignupReducer>

    init(state: EmailSignupReducer.State, reducer: EmailSignupReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: 20)

                    VStack(alignment: .leading) {
                        Text("이메일 회원가입")
                            .textStyle(size: 24, color: .anipickBlack, weight: .semibold)
                            .padding(.bottom, 4)

                        Text("회원 서비스 이용을 위해 회원 가입을 진행해주세요.")
                            .textStyle(size: 14, color: .anipickBlack)
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

                    passwordSection()

                    Spacer().frame(height: 64)

                    agreements()
                }
            }

            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)
                .padding(.vertical, 23)

            PrimaryButton("회원가입하기", isEnabled: store.state.isSignupEnabled) {
                store.send(.signupTapped)
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
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .background(Color.white)
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func passwordSection() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("비밀번호")
                    .textStyle(size: 18, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 12)
                Spacer()

                Image(store.state.isPasswordValid ? .check : .uncheck)
            }

            PasswordInputField(
                text: Binding(
                    get: { store.state.password },
                    set: { store.send(.passwordChanged($0)) }
                ),
                isVisible: store.state.isPasswordVisible
            ) {
                store.send(.passwordVisibilityTapped)
            }

            // 비어 있으면 회색 도움말, 아니면 빨간 안내 (SU2)
            if store.state.password.isEmpty {
                Text("8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해주세요.")
                    .textStyle(size: 12, color: .gray8)
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
            } else {
                Text(store.state.passwordGuide)
                    .textStyle(size: 12, color: .point)
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func agreements() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Text("애니픽 이용을 위해 동의가 필요해요.")
                .textStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 17)

            Button {
                store.send(.agreeAllTapped)
            } label: {
                Rectangle()
                    .cornerRadius(8)
                    .foregroundStyle(.gray5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay {
                        HStack(spacing: 0) {
                            Image(store.state.agreesAll ? .check : .uncheck)
                                .padding(.horizontal, 10)

                            Text("모두 동의합니다.")
                                .font(.system(size: 14))
                                .foregroundStyle(.anipickBlack)

                            Spacer()
                        }
                    }
            }
            .padding(.bottom, 17)

            agreementRow("[필수] 만 14세 이상입니다.", store.state.agreesOverFourteen) {
                store.send(.overFourteenTapped)
            }
            .padding(.bottom, 11)

            agreementRow("[필수] 이용약관에 동의합니다.", store.state.agreesTerms) {
                store.send(.termsTapped)
            }
            .padding(.bottom, 11)

            agreementRow("[필수] 개인정보 처리방침에 동의합니다.", store.state.agreesPrivacy) {
                store.send(.privacyTapped)
            }

            Spacer()
        }
    }

    private func agreementRow(_ title: String, _ isOn: Bool, action: @escaping () -> Void)
        -> some View
    {
        return Button {
            action()
        } label: {
            HStack(spacing: 0) {
                Image(isOn ? .check : .uncheck)
                    .padding(.trailing, 18)

                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(.anipickBlack)

                Spacer()

                Image(.chevronLeftGray)
            }
        }
    }
}
