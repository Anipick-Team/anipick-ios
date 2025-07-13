//
//  MainLoginView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI
import UIKit
import AuthenticationServices

struct MainLoginView: View {
    @StateObject var viewModel: MainLoginViewModel
    
    var body: some View {
            VStack(spacing: 0) {
                Spacer()
                Image("AniPickLogo_green")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                
                Spacer()
                    .frame(height: 48)
                
                VStack(spacing: 0) {
                    Text("나에게 딱 맞는 애니 추천을 위해.")
                        .customFontStyle(size: 24, color: .anipickBlack, weight: .bold)
                        .padding(.bottom, 8)
                    Text("사용할수록 더 좋아지는 애니메이션 환경을 만나보세요")
                        .customFontStyle(size: 14, color: .anipickBlack)
                }
                .padding(.bottom, 60)
                
                Button {
                    DLog("kakao로 로그인 하기")
                    viewModel.getKakaoAccessToken()
                    
                } label: {
                    Image(.kakaoLoginButton)
                        .padding(.bottom, 12)
                }
                
                Button {
                    DLog("google로 로그인 하기")
                    viewModel.getGoogleIDToken()
                } label: {
                    Image(.googleLoginButton)
                        .background(.white)
                        .padding(.bottom, 12)
                }
                            
                SignInWithAppleButton(
                    onRequest: viewModel.configure,
                    onCompletion: viewModel.handle
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 45)
                .padding()
                
                
                HStack(spacing: 0) {
                    Button {
                        viewModel.tappedEmailSignup()
                        DLog("이메일 회원가입 눌림")
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
                        viewModel.tappedEmailLogin()
                        DLog("이메일로그인 눌림")
                    } label: {
                        Text("이메일 로그인")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gray)
                    }
                }
                
                Spacer()
                
                Button {
                    viewModel.tappedProblemLoginButton()
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
            .background(.white)
    }
    
    private func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
               let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                if let data = String(data: appleIDCredential.authorizationCode!, encoding: .utf8) {
                    print("authCode: \(data))")
                }
                print("User ID: \(userIdentifier)")
                print("Full Name: \(String(describing: fullName))")
                print("Email: \(String(describing: email))")
                appleIDCredential.authorizationCode
                print("user: \(appleIDCredential.identityToken)")
                print("state: \(appleIDCredential.state)")
            }
        case .failure(let error):
            print("Authorization failed: \(error.localizedDescription)")
        }
    }
}


#Preview {
  //  AppDIContainer.makeLoginView()
   // MainLoginView()
}
