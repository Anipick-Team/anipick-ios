//
//  EmailSigninView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct EmailSignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationManager: NavigationManager
    
    @StateObject var viewModel: EmailSignupViewModel
    
    var body: some View {
    //    NavigationStack(path: $navigationManager.path) {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment:.leading, spacing: 0) {
                        Spacer()
                            .frame(height: 29)
                        
                        VStack(alignment: .leading) {
                            Text("이메일 회원가입")
                                .customFontStyle(size: 24, color: .anipickBlack, weight: .semibold)
                                .padding(.bottom, 4)
                            
                            Text("회원 서비스 이용을 위해 회원 가입을 진행해주세요.")
                                .customFontStyle(size: 14, color: .anipickBlack)
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
                        
                        VStack(alignment:.leading, spacing: 0) {
                            HStack(spacing: 0 ) {
                                Text("비밀번호")
                                    .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                                    .padding(.bottom, 12)
                                Spacer()
                                
                                Image(viewModel.isValidPassword() ? .check : .uncheck)
                            }
                            
                            ZStack {
                                SecureField(
                                    "",
                                    text: $viewModel.passwordString,
                                    prompt: Text("비밀번호를 입력해주세요")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.textGray)
                                )
                                .padding(16)
                                .background(.textFieldBackground)
                                .cornerRadius(8)
                                
                                HStack {
                                    Spacer()
                                    Image(.eyeUnvisibleIcons)
                                        .padding(.trailing, 15)
                                }
                            }
                            
                            Text("8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해주세요.")
                                .customFontStyle(size: 12, color: .gray8)
                                .padding(.top, 8)
                                .padding(.horizontal, 4)
                        }
                        
                        Spacer().frame(height: 64)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("애니픽 이용을 위해 동의가 필요해요.")
                                .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                                .padding(.bottom, 17)
                            
                            Button {
                                DLog("전체 동의 탭")
                                viewModel.toggleAllAgreement()
                            } label: {
                                Rectangle()
                                    .cornerRadius(8)
                                    .foregroundStyle(.gray5)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .overlay {
                                        HStack(spacing: 0) {
                                            Image(viewModel.isAgreeAll ? .check : .uncheck)
                                                .padding(.horizontal, 10)
                                            
                                            Text("모두 동의합니다.")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.anipickBlack)
                                            
                                            Spacer()
                                        }
                                    }
                            }
                            .padding(.bottom, 17)
                            
                            Button {
                                DLog("Tapped 만 14세 이상 버튼")
                                viewModel.toggleOverFourteen()
                            } label: {
                                HStack(spacing: 0) {
                                    Image(viewModel.isAgreeOverFourteen ? .check : .uncheck)
                                        .padding(.trailing, 18)
                                    
                                    Text("[필수] 만 14세 이상입니다.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.anipickBlack)
                                    
                                    Spacer()
                                    
                                    Image(.chevronLeftGray)
                                }
                            }
                            .padding(.bottom, 11)
                            
                            Button {
                                DLog("Tapped 이용약관 동의")
                                viewModel.toggleTermsOfUse()
                            } label: {
                                HStack(spacing: 0) {
                                    Image(viewModel.isAgreeTermsOfUse ? .check : .uncheck)
                                        .padding(.trailing, 18)
                                    
                                    Text("[필수] 이용약관에 동의합니다.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.anipickBlack)
                                    
                                    Spacer()
                                    
                                    Image(.chevronLeftGray)
                                }
                            }
                            .padding(.bottom, 11)
                            
                            Button {
                                DLog("Tapped 개인정보처리방침")
                                viewModel.togglePrivacyPolicy()
                            } label: {
                                HStack(spacing: 0) {
                                    Image(viewModel.isAgreePrivacyPolicy ? .check : .uncheck)
                                        .padding(.trailing, 18)
                                    
                                    Text("[필수] 개인정보 처리방침에 동의합니다.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.anipickBlack)
                                    
                                    Spacer()
                                    
                                    Image(.chevronLeftGray)
                                }
                            }
                            
                        }
                        
                        Spacer()
                        
                    }
                }
                
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundStyle(.gray6)
                    .padding(.horizontal, -20)
                    .padding(.vertical, 23)
                
                FullWidthButton(
                    isEnable: $viewModel.isEnableLoginButton,
                    buttonText: "회원가입하기"
                ) {
                    DLog("회원가입 버튼 탭")
                    Task {
                        await viewModel.signupWithEmail()
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
        }
  //  }
}

#Preview {
    //  AppDIContainer.makeEmailSignupView()
}
