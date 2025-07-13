//
//  AuthTestView.swift
//  AniPick
//
//  Created by cho on 6/4/25.
//

import SwiftUI
import AuthenticationServices

struct AuthTestView: View {
    @StateObject var viewModel: MainLoginViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                Button("kakaologin") {
                    DLog("kakaologin 버튼 눌림")
                    viewModel.postSocialLogin(
                        provider: "KAKAO",
                        code: "qqh-wUorqHpGE6vQJcDdgsp8dMMWCI4QAAAAAQoXBi4AAAGXXmJgk_6hmr4nKm-b"
                    )
                }
                .padding()
                
                Button("googlelogin") {
                    DLog("googlelogin 버튼 눌림")
                    viewModel.postSocialLogin(
                        provider: "GOOGLE",
                        code: "eyJhbGciOiJSUzI1NiIsImtpZCI6IjBkOGE2NzM5OWU3ODgyYWNhZTdkN2Y2OGIyMjgwMjU2YTc5NmE1ODIiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiIzNzY4MDg3NzcyNjctNmJzNjZhZDZrdHRjM3M3dmRuc25pYnJnMTZnZGxzdmguYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiIzNzY4MDg3NzcyNjctNmJzNjZhZDZrdHRjM3M3dmRuc25pYnJnMTZnZGxzdmguYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDM0NDEwNzI1NTk0ODY3NTI5NjAiLCJlbWFpbCI6InNscG0zOTU3NTg1OEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6Ims0UGZZR1hXdGpjWERuaFFLYzRWeGciLCJub25jZSI6IkprekJReFJfLUIxTEFyYXFHcU5vdWhBdDM3ankzRHVjUjBXS3FLalV5RFEiLCJuYW1lIjoi7KGw7LGE7JuQIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0x3LW5SMzlKQU9YMEVqWUMwOFE3Q3I4NTV0TFFTV0RjT1J5d3hLMzlRSnNaOFo3dz1zOTYtYyIsImdpdmVuX25hbWUiOiLssYTsm5AiLCJmYW1pbHlfbmFtZSI6IuyhsCIsImlhdCI6MTc0OTYzNTIyMSwiZXhwIjoxNzQ5NjM4ODIxfQ.grqj-WGtHGwg19ecE2PTj9YAB-NL8zmyLIfiNahpv_JGgN1rnGmj4rLMmoxo8Y6EIJ1kMqnnMSGUJO2SwdJHkUg8OqogAu6NQqLPoPp4a_nfJsMM9uZXuh5VdNoCJpqldd2xd0kz2txzyzkkojvS9_sDryRYw5lT0Wi1MlRmeM5atZgCYrw5Zt93eHUsFIDzZgEa99o_R9TR6kr4uBOYuvH6UO7rSYLWDBf0HLCeIczNuOL-3GZNyadACsBSdof5m-RTaTibR5nVIyLFg8P2bFrXXd9teSr6akZmpVA8u06uyf5POB30L0u5oymzAUAP72Kb-kJ25MmOnGpa5c-Llg"
                    )
                }
                .padding()
                
                Button("apppleLogin") {
                    DLog("apppleLogin 버튼 눌림")
                    viewModel.postSocialLogin(
                        provider: "APPLE",
                        code: "cwcho_etoos"
                    )
                }
                .padding()
                
                Button("refresh token") {
                    DLog("refresh token 버튼 눌림")
                    viewModel.refreshToken(refreshToken: "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJzbHBtMzk1N0BuYXZlci5jb20iLCJpYXQiOjE3NDk2MzgzNDYsImV4cCI6MTc1MDg0Nzk0Nn0.ugFZU5HOJrYiFU1Jk7RiC89enOASIGdgIP8XkBnGl_qzWJ3pRmZsaQrZ57SBrgx9LVydI9M6v0LfVEb16rUJFg")
                }
                .padding()
                
                Button("logout") {
                    DLog("logout 버튼 눌림")
                    viewModel.tappedLogout(accessToken: "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJzbHBtMzk1N0BuYXZlci5jb20iLCJpYXQiOjE3NDk2Mzc0NDMsImV4cCI6MTc0OTY0MTA0M30.Vy_rB4s-OvyAmAvEg53ykc1x7tBxxJWN4pgUeBjtMEr1jc68OAnRa11eYi6hjBaPY5VoEERWB43tovFkPJBJCQ")
                }
                .padding()
                
                Button("emailSignup") {
                    DLog("emailSignup 버튼 눌림")
                //    viewModel.emailSignup()
                }
                .padding()
                
                Button("emailLogin") {
                    DLog("emailLogin 버튼 눌림")
                 //   viewModel.emailLogin()
                }
                .padding()
                
                Button("sendingEmail") {
                    DLog("sendingEmail 버튼 눌림")
                    viewModel.findPassword()
                }
                .padding()
                
                Button("sendEmailVaildateNumber") {
                    DLog("sendEmailVaildateNumber 버튼 눌림")
                    viewModel.vaildateNumber()
                }
                .padding()
                
                Button("resetPassword") {
                    DLog("resetPassword 버튼 눌림")
                    viewModel.resetPassword()
                }
                .padding()
            }
        }
    }
}
