//
//  EditPasswordView.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI

struct EditPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: EditPasswordViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)
            
            NavigationBackButtonView(title: "비밀번호 변경") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 36)
                        
            securityPasswordView(
                title: "현재 비밀번호",
                isShowCheck: nil,
                textFieldText: $viewModel.currentPassword,
                placeholderText: "현재 비밀번호",
                eyeVisibleIcons: false,
                errorMessage: viewModel.currentPasswordErrorMessage
            )
            
            Spacer().frame(height: 32)
            
            
            securityPasswordView(
                title: "새 비밀번호",
                isShowCheck: true,
                textFieldText: $viewModel.newPassword,
                placeholderText: "영문, 숫자, 특수문자 2개 이상 조합, 10자 이상",
                eyeVisibleIcons: false,
                errorMessage: viewModel.NewErrorMessage
            )
 
            Spacer().frame(height: 32)
            
            securityPasswordView(
                title: "새 비밀번호 확인",
                isShowCheck: true,
                textFieldText: $viewModel.checkNewPassword,
                placeholderText: "비밀번호 확인",
                eyeVisibleIcons: false,
                errorMessage: viewModel.NewErrorMessage
            )
          
            Spacer()
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, -40)
                .frame(height: 1)
                .foregroundStyle(Color.gray6)
            
            Spacer().frame(height: 32)
            
            // TODO: ViewModel 연결해서 enable 동작하게 만들기 / 탈퇴 액션
            FullWidthButton(
                isEnable: .constant(true),
                buttonText: "저장") {
                    DLog("닉네임 변경 저장 액션")
                }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
    }
    
    private func obfuscateEmail(_ email: String) -> String {
        return email.replacingOccurrences(of: "@", with: "@\u{200B}")
    }
    @ViewBuilder
    private func sectionDivder() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
        
    }
    
    @ViewBuilder
    private func securityPasswordView(
        title: String,
        isShowCheck: Bool?,
        textFieldText: Binding<String>,
        placeholderText: String,
        eyeVisibleIcons: Bool,
        errorMessage: String?
    ) -> some View {
        VStack(alignment:.leading, spacing: 0) {
            HStack(spacing: 0 ) {
                Text(title)
                    .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 12)
                Spacer()
                
                if let isShowCheck {
                    Image(isShowCheck ? .check : .uncheck)
                }
            }
            
            ZStack {
                SecureField(
                    "",
                    text: textFieldText,
                    prompt: Text(placeholderText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textGray)
                )
                .padding(16)
                .background(.textFieldBackground)
                .cornerRadius(8)
                
                HStack {
                    Spacer()
                    
                    Button {
                        // TODO: 버튼 눌렀을 때 바뀌는 거 처리해야함
                    } label : {
                        Image(eyeVisibleIcons ? .eyeVisibleIcons : .eyeUnvisibleIcons)
                            .padding(.trailing, 15)
                    }
                }
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .customFontStyle(size: 14, color: .point, weight: .semibold)
                    .padding(.top, 8)
            } else {
                
            }
        }
    }
}

#Preview {
    AppDIContainer.makeEditPasswordView()
}
