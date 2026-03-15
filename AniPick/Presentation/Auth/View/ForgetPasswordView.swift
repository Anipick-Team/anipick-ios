//
//  ForgetPasswordView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct ForgetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: ForgetPasswordViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 64)
            
            VStack(alignment: .leading) {
                Text("비밀번호 찾기")
                    .customFontStyle(size: 24, color: .anipickBlack, weight: .semibold)
                   .padding(.bottom, 4)
                   .padding(.bottom, 4)
                
                Text("회원 서비스 사용을 위해 비밀번호를 찾아주세요.")
                    .customFontStyle(size: 14, color: .gray8)
            }
            
            Spacer().frame(height: 64)
            
            Text("이메일")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .semibold)
                .padding(.bottom, 12)
            
            HStack(spacing: 0) {
                TextField(
                    "",
                    text: $viewModel.emailString,
                    prompt: Text("이메일을 입력해주세요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textGray)
                )
                .autocapitalization(.none)
                .padding(16)
                .foregroundColor(.anipickBlack)
                .background(.textFieldBackground)
                .cornerRadius(8)
                
                Button {
                    DLog("인증번호 받기 탭탭")
                    Task {
                        await viewModel.tappedValidNumberButton()
                    }
                } label: {
                    Text(viewModel.validNumButtonText)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .frame(width: 120, height: 50)
                        .background(viewModel.isValidNumButtonEnabled ? Color.anipickPrimary : Color.gray)
                        .cornerRadius(8)
                        .padding(.leading, 12)
                }
                .disabled(!viewModel.isValidNumButtonEnabled)
            }
            
            Text(viewModel.emailGuideText)
                .customFontStyle(size: 14, color: .point)
                .padding(.top, 12)
                .padding(.leading, 2)
            
            Spacer().frame(height: 40)
            
            ZStack {
                TextFieldComponents(
                    titleText: "인증번호",
                    placeholderText: "인증번호를 입력해주세요",
                    textFieldString: $viewModel.verificationCode,
                    enableTimer: true,
                    timerCount: viewModel.timerCount
                )
            }
            
            Text(viewModel.validNumeberGuideText)
                .customFontStyle(size: 14, color: .point)
                .padding(.top, 12)
                .padding(.leading, 2)
            
            Spacer().frame(height: 40)
            
            Spacer()
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)
                .padding(.bottom, 32)
            
            
            FullWidthButton(isEnable: $viewModel.activeNextButton, buttonText: "다음") {
                Task {
                    await self.viewModel.tappedNextButton()
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
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        
    }
}

#Preview {
    AppDIContainer.makeFindPasswordView()
}


