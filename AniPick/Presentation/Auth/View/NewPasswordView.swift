//
//  NewPasswordView.swift
//  AniPick
//
//  Created by cho on 7/17/25.
//

import SwiftUI

struct NewPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var isVisibleIcons: Bool = false
    @State private var isVisibleIconsRepeat: Bool = false

    @StateObject var viewModel: ForgetPasswordViewModel
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 28)
            
            VStack(alignment: .leading) {
                Text("비밀번호 찾기")
                    .customFontStyle(size: 24, color: .anipickBlack, weight: .semibold)
                    .padding(.bottom, 4)
                
                Text("회원 서비스 이용을 위해 비밀번호를 찾아주세요.")
                    .customFontStyle(size: 14, color: .textGray)
            }
            
            Spacer().frame(height: 64)
            
//            ZStack {
//                SecureField(
//                    "",
//                    text: $viewModel.newPassword,
//                    prompt: Text("새 비밀번호를 입력해주세요")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(.textGray)
//                )
//                .padding(16)
//                .background(.textFieldBackground)
//                .cornerRadius(8)
//                .autocapitalization(.none)
//                
//                HStack {
//                    Spacer()
//                    Image(.eyeUnvisibleIcons)
//                        .padding(.trailing, 15)
//                }
//            }
            
            ZStack {
                if isVisibleIcons {
                    TextField(
                        "",
                        text: $viewModel.newPassword,
                        prompt: Text("비밀번호를 입력해주세요")
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
                        prompt: Text("비밀번호를 입력해주세요")
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
                        self.isVisibleIcons.toggle()
                    } label: {
                        Image(self.isVisibleIcons ? .eyeVisibleIcons : .eyeUnvisibleIcons )
                            .padding(.trailing, 15)
                    }
                }
            }
            
            Text("8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해주세요.")
                .customFontStyle(size: 12, color: .gray8)
                .padding(.top, 8)
                .padding(.horizontal, 4)
            
            Spacer().frame(height: 40)
            
            
            ZStack {
                if isVisibleIconsRepeat {
                    TextField(
                        "",
                        text: $viewModel.checkNewPassword,
                        prompt: Text("새 비밀번호를 다시 한 번 입력해주세요")
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
                        prompt: Text("새 비밀번호를 다시 한 번 입력해주세요")
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
                        self.isVisibleIconsRepeat.toggle()
                    } label: {
                        Image(self.isVisibleIconsRepeat ? .eyeVisibleIcons : .eyeUnvisibleIcons )
                            .padding(.trailing, 15)
                    }
                }
            }
            
//            ZStack {
//                SecureField(
//                    "",
//                    text: $viewModel.checkNewPassword,
//                    prompt: Text("새 비밀번호를 다시 한 번 입력해주세요")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(.textGray)
//                )
//                .padding(16)
//                .background(.textFieldBackground)
//                .cornerRadius(8)
//                
//                HStack {
//                    Spacer()
//                    Image(.eyeUnvisibleIcons)
//                        .padding(.trailing, 15)
//                }
//            }
//            TextFieldComponents(
//                titleText: "새 비밀번호 확인",
//                placeholderText: "새 비밀번호를 다시 한 번 입력해주세요",
//                textFieldString: $viewModel.checkNewPassword,
//                enableEyeIcon: true
//            )

//            Spacer().frame(height: 40)
//            
//            VStack(spacing: 0) {
//                HStack(alignment: .center, spacing: 0) {
//                    Spacer()
//                    
//                    Button {
//                        self.navigationManager.push(route: AppRoute.emailSignup)
//                        print("tapped 회원가입")
//                    } label: {
//                        Text("회원가입")
//                    }
//                    
//                    Rectangle()
//                        .frame(width: 1, height: 15)
//                        .padding(.horizontal, 20)
//                    
//                    Button {
//                        self.navigationManager.push(route: AppRoute.findPassword)
//                        print("tapped 비밀번호 찾기")
//                    } label: {
//                        Text("비밀번호 찾기")
//                    }
//                    
//                    Spacer()
//                    
//                }
//                .font(.system(size: 14))
//                .foregroundStyle(.textGray)
//            }
            
            Spacer()
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 32)
            
            FullWidthButton(
                isEnable: $viewModel.isEnableFindPasswordButton,
                buttonText: "비밀번호 변경 완료"
            ) {
                DLog("비밀번호 변경 완료 버튼")
                Task {
                    await viewModel.resetPassword()
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
