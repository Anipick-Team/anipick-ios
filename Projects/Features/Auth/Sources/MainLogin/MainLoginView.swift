import AuthClientInterface
import AuthenticationServices
import DesignSystem
import MVICore
import SwiftUI

/// 레거시 `MainLoginView`와 같은 배치
struct MainLoginView: View {
    @State private var store: Store<MainLoginReducer>

    init(state: MainLoginReducer.State, reducer: MainLoginReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                Image(.aniPickLogoGreen)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)

                Spacer()
                    .frame(height: 48)

                VStack(spacing: 0) {
                    Text("나에게 딱 맞는 애니 추천을 위해.")
                        .textStyle(size: 24, color: .anipickBlack, weight: .bold)
                        .padding(.bottom, 8)
                    Text("사용할수록 더 좋아지는 애니메이션 환경을 만나보세요")
                        .textStyle(size: 14, color: .anipickBlack)
                }
                .padding(.bottom, 60)

                Button {
                    store.send(.kakaoTapped)
                } label: {
                    Image(.kakaoLoginButton)
                        .padding(.bottom, 12)
                }

                Button {
                    store.send(.googleTapped)
                } label: {
                    Image(.googleLoginButton)
                        .background(.white)
                        .padding(.bottom, 12)
                }

                SignInWithAppleButton { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    store.send(.appleCompleted(Self.outcome(result)))
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 45)
                .padding()

                HStack(spacing: 0) {
                    Button {
                        store.send(.emailSignupTapped)
                    } label: {
                        Text("이메일 회원가입")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gray)
                    }

                    Rectangle()
                        .frame(width: 1, height: 15)
                        .foregroundStyle(Color.gray)
                        .padding(.horizontal, 10)

                    Button {
                        store.send(.emailLoginTapped)
                    } label: {
                        Text("이메일 로그인")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gray)
                    }
                }

                Spacer()

                Button {
                    store.send(.problemTapped)
                } label: {
                    RoundedRectangle(cornerRadius: 21)
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 190, height: 30)
                        .foregroundStyle(Color.white)
                        .overlay {
                            Text("로그인에 문제가 있으신가요?")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.gray)
                        }
                        .padding(.bottom, 50)
                }
            }
            .background(Color.white.ignoresSafeArea())

            if store.state.isWithdrawnPopupPresented {
                WithdrawnUserPopup {
                    store.send(.withdrawnPopupClosed)
                }
            }

            // 레거시 SNSSignupPopupView: 어두운 배경 + 팝업 (DesignSystem popup이 같은 모양)
            Color.clear
                .popup(isPresented: store.state.existingAccount != nil) {
                    if let account = store.state.existingAccount {
                        ConfirmPopup(
                            title: account.title,
                            message: account.message,
                            cancelTitle: "닫기",
                            confirmTitle: account.confirmTitle,
                            onCancel: { store.send(.existingAccountClosed) },
                            onConfirm: { store.send(.existingAccountConfirmed) }
                        )
                    }
                }
        }
        .navigationBarBackButtonHidden(true)
    }

    /// 레거시 `MainLoginViewModel.handle`의 분기
    static func outcome(_ result: Result<ASAuthorization, any Error>)
        -> MainLoginReducer.AppleOutcome
    {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
            else {
                return .credentialCastFailed
            }
            guard
                let data = credential.identityToken,
                let token = String(data: data, encoding: .utf8),
                !token.isEmpty
            else {
                return .emptyIdentityToken
            }
            return .token(token)
        case .failure(let error):
            return .failed(error as NSError)
        }
    }
}

extension ExistingAccount {
    private var name: String {
        switch self {
        case .email:
            return "이메일"
        case .kakao:
            return "카카오"
        case .google:
            return "구글"
        case .apple:
            return "애플"
        }
    }

    /// 레거시 `ExistingAccountType`과 같은 문구
    var title: String {
        return "\(name)로 가입된 계정입니다."
    }

    var message: String {
        return "\(name)로 로그인해주세요."
    }

    var confirmTitle: String {
        return "\(name)로 로그인"
    }
}
