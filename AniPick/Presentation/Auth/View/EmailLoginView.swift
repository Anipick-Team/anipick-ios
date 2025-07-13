//
//  EmailLoginView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct EmailLoginView: View {
    
    @StateObject var viewModel: EmailLoginViewModel = EmailLoginViewModel()
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 34)
            
            VStack(alignment: .leading) {
                Text("이메일 로그인")
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.bottom, 4)
                
                Text("회원 서비스 이용을 위해 로그인 해주세요.")
                    .font(.system(size: 14, weight: .medium))
            }
            
            Spacer().frame(height: 64)
            
            TextFieldComponents(
                titleText: "이메일",
                placeholderText: "이메일을 입력해주세요",
                textFieldString: $viewModel.emailString
            )
            
            Spacer().frame(height: 40)
            
            TextFieldComponents(
                titleText: "비밀번호",
                placeholderText: "비밀번호를 입력해주세요",
                textFieldString: $viewModel.passwordString,
                enableEyeIcon: true
            )

            Spacer().frame(height: 40)
            
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    Spacer()
                    
                    Button {
                        print("tapped 회원가입")
                    } label: {
                        Text("회원가입")
                    }
                    
                    Rectangle()
                        .frame(width: 1, height: 15)
                        .padding(.horizontal, 20)
                    
                    Button {
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
            
            FullWidthButton(isEnable: $viewModel.isEnableLoginButton, buttonText: "로그인") {
                print("로그인 버튼 탭")
            }
            .padding(.bottom, 16)
           
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        
        
    }
}

#Preview {
    EmailLoginView()
}
