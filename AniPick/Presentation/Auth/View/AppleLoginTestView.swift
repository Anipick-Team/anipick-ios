//
//  AppleLoginTestView.swift
//  AniPick
//
//  Created by cho on 5/27/25.
//

import SwiftUI
import AuthenticationServices

struct AppleLoginTestView: View {
    var body: some View {
        SignInWithAppleButton(
            onRequest: configure,
            onCompletion: handle
        )
        .signInWithAppleButtonStyle(.black)
        .background(Color.white)
        .frame(height: 45)
        .padding()
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
    AppleLoginTestView()
}
