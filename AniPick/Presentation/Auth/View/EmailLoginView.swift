//
//  EmailLoginView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct EmailLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var isVisibleIcons: Bool = false
    @StateObject var viewModel: EmailLoginViewModel
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 28)
            
            VStack(alignment: .leading) {
                Text("이메일 로그인")
                    .customFontStyle(size: 24, color: .anipickBlack, weight: .semibold)
                    .padding(.bottom, 4)
                
                Text("회원 서비스 이용을 위해 로그인 해주세요.")
                    .customFontStyle(size: 14, color: .textGray)
            }
            
            Spacer().frame(height: 64)
            
            TextFieldComponents(
                titleText: "이메일",
                placeholderText: "이메일을 입력해주세요",
                textFieldString: $viewModel.emailString
            )
            .autocapitalization(.none)
            
            Text(viewModel.emailGuideText)
                .customFontStyle(size: 14, color: .point)
            
            Spacer().frame(height: 40)
            
            
            ZStack {
                if isVisibleIcons {
                    TextField(
                        "",
                        text: $viewModel.passwordString,
                        prompt: Text("비밀번호를 입력해주세요")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
                } else {
                    SecureField(
                        "",
                        text: $viewModel.passwordString,
                        prompt: Text("비밀번호를 입력해주세요")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
                }
                
                HStack {
                    Spacer()
                    
                    Button {
                        self.isVisibleIcons.toggle()
                    } label: {
                        Image(self.isVisibleIcons ? .eyeVisibleIcons : .eyeUnvisibleIcons )
                            .padding(.trailing, 15)
                    }
                }
            }
        
            Spacer().frame(height: 40)
            
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    Spacer()
                    
                    Button {
                        self.navigationManager.push(route: AppRoute.emailSignup)
                        print("tapped 회원가입")
                    } label: {
                        Text("회원가입")
                    }
                    
                    Rectangle()
                        .frame(width: 1, height: 15)
                        .padding(.horizontal, 20)
                    
                    Button {
                        self.navigationManager.push(route: AppRoute.findPassword)
                        print("tapped 비밀번호 찾기")
                    } label: {
                        Text("비밀번호 찾기")
                    }
                    
                    Spacer()
                    
                }
                .font(.system(size: 14))
                .foregroundStyle(.textGray)
            }
            
            Spacer()
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 32)
            
            FullWidthButton(
                isEnable: $viewModel.isEnableLoginButton,
                buttonText: "로그인"
            ) {
                print("로그인 버튼 탭")
                Task {
                    await viewModel.loginWithEmail()
                }
            }
            .padding(.bottom, 16)
           
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(.chevronLeft)
                        .foregroundColor(.black)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .background(Color.white)
        
        
    }
}

#Preview {
   // AppDIContainer.makeEmailLoginView()
}
