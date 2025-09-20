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
    
    @State private var isVisibleIconsCurrentPW: Bool = false
    @State private var isVisibleIconsNewPW: Bool = false
    @State private var isVisibleIconsCheckPW: Bool = false
    
    
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
                        
            Text("현재 비밀번호")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)
            
            ZStack {
                if isVisibleIconsCurrentPW {
                    TextField(
                        "",
                        text: $viewModel.currentPassword,
                        prompt: Text("현재 비밀번호")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .autocapitalization(.none)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
                } else {
                    SecureField(
                        "",
                        text: $viewModel.currentPassword,
                        prompt: Text("현재 비밀번호")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .autocapitalization(.none)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)

                }
                
                HStack {
                    Spacer()
                    
                    Button {
                        self.isVisibleIconsCurrentPW.toggle()
                    } label: {
                        Image(self.isVisibleIconsCurrentPW ? .eyeVisibleIcons : .eyeUnvisibleIcons )
                            .padding(.trailing, 15)
                    }
                }
            }
            
            if viewModel.currentPasswordErrorMessage.isEmpty == false {
                Text(viewModel.currentPasswordErrorMessage)
                    .customFontStyle(size: 14, color: .point, weight: .semibold)
                    .padding(.top, 8)
            }

            Spacer().frame(height: 32)
            
            Text("새 비밀번호")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)
            
                Image(self.viewModel.isValidatePassword ? .check : .uncheck)
            
            
            ZStack {
                if isVisibleIconsNewPW {
                    TextField(
                        "",
                        text: $viewModel.newPassword,
                        prompt: Text("영문, 숫자, 특수문자 2개 이상 조합, 10자 이상")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .autocapitalization(.none)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
                } else {
                    SecureField(
                        "",
                        text: $viewModel.newPassword,
                        prompt: Text("영문, 숫자, 특수문자 2개 이상 조합, 10자 이상")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .autocapitalization(.none)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)

                }
                
                HStack {
                    Spacer()
                    
                    Button {
                        self.isVisibleIconsNewPW.toggle()
                    } label: {
                        Image(self.isVisibleIconsNewPW ? .eyeVisibleIcons : .eyeUnvisibleIcons )
                            .padding(.trailing, 15)
                    }
                }
            }
            
            if viewModel.NewErrorMessage.isEmpty == false {
                Text(viewModel.NewErrorMessage)
                    .customFontStyle(size: 14, color: .point, weight: .semibold)
                    .padding(.top, 8)
            }
            
            Spacer().frame(height: 32)
            
            Text("새 비밀번호 확인")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)
            
            Image(self.viewModel.isShowGreenCheckDoublePW ? .check : .uncheck)
            
            
            ZStack {
                if isVisibleIconsCheckPW {
                    TextField(
                        "",
                        text: $viewModel.checkNewPassword,
                        prompt: Text("비밀번호 확인")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .autocapitalization(.none)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
                } else {
                    SecureField(
                        "",
                        text: $viewModel.checkNewPassword,
                        prompt: Text("비밀번호 확인")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .autocapitalization(.none)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)

                }
                
                HStack {
                    Spacer()
                    
                    Button {
                        self.isVisibleIconsCheckPW.toggle()
                    } label: {
                        Image(self.isVisibleIconsCheckPW ? .eyeVisibleIcons : .eyeUnvisibleIcons )
                            .padding(.trailing, 15)
                    }
                }
            }
            
            if viewModel.checkNewErrorMessage.isEmpty == false {
                Text(viewModel.checkNewErrorMessage)
                    .customFontStyle(size: 14, color: .point, weight: .semibold)
                    .padding(.top, 8)
            }
    
          
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
                    DLog("비밀번호 변경 저장 탭탭")
                    viewModel.editPassword()
                }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .background(Color.white)
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
}

#Preview {
    AppDIContainer.makeEditPasswordView()
}
