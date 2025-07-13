//
//  ForgetPasswordView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct ForgetPasswordView: View {
    @State var emailString: String = ""
    
    @StateObject var viewModel: ForgetPasswordViewModel = ForgetPasswordViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 34)
            
            VStack(alignment: .leading) {
                Text("비밀번호 찾기")
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.bottom, 4)
                
                Text("회원 서비스 사용을 위해 비밀번호를 찾아주세요.")
                    .font(.system(size: 14, weight: .medium))
            }
            
            Spacer().frame(height: 64)
            
            HStack(spacing: 0) {
                TextField(
                    "",
                    text: $emailString,
                    prompt: Text("이메일을 입력해주세요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textGray)
                )
                .padding(16)
                .background(.textFieldBackground)
                .cornerRadius(8)
                
                Button {
                    print("인증번호 받기 탭탭")
                } label: {
                    Text("인증번호 받기")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.anipickPrimary)
                        .cornerRadius(8)
                }
            }
            
            Spacer().frame(height: 40)
            
            TextFieldComponents(
                titleText: "인증번호",
                placeholderText: "비밀번호를 입력해주세요",
                textFieldString: $viewModel.verificationCode,
                enableEyeIcon: true
            )

            Spacer().frame(height: 40)
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 32)
            
            FullWidthButton(isEnable: $viewModel.activeLoginButton, buttonText: "로그인") {
                print("로그인 버튼 탭")
            }
            .padding(.bottom, 16)
           
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        
    }
}

#Preview {
    ForgetPasswordView()
}
