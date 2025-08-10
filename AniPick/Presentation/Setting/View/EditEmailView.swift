//
//  EditEmailView.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI

struct EditEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: EditEmailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)
            
            NavigationBackButtonView(title: "이메일 변경") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 36)
                        
            Text("기존 이메일")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)
                
            let email = UserDefaultsManager.shared.getEmail()
            Text(email)
                .customFontStyle(size: 16, color: .anipickBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 20)
                .padding(16)
                .background(Color.gray5)
                .cornerRadius(8)
                .multilineTextAlignment(.leading)
                
            Spacer().frame(height: 32)
            
            TextFieldComponents(
                titleText: "새 이메일",
                placeholderText: "새 이메일 입력",
                textFieldString: $viewModel.newEmailString
            )
            .padding(.bottom, 12)
            
            // TODO: 이메일 관련 오류 메시지 보내야함
            if viewModel.isInvalidEmail {
                Text("이미 존재하는 이메일입니다.")
                    .customFontStyle(size: 14, color: .point, weight: .semibold)
            }
            
            
            // TODO: 이미 사용중인지 확인하는 api 보내는 통신해야함
            if viewModel.isShowErrorMessage {
                Text(viewModel.errorMessage)
                    .customFontStyle(size: 14, color: .point, weight: .semibold)
            } else {
                Spacer().frame(height: 30)
            }
            
            TextFieldComponents(
                titleText: "비밀번호",
                placeholderText: "텍스트를 입력",
                textFieldString: $viewModel.passwordString,
                enableEyeIcon: true
            )
            .padding(.bottom, 12)
            
            // TODO: 비밀번호 관련 오류 메시지 보내야함
            if viewModel.isInvalidPassword {
                Text("비밀번호가 일치하지 않습니다.")
                    .customFontStyle(size: 14, color: .point, weight: .semibold)
            }
            
            Spacer().frame(height: 30)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("•")
                        .padding(.trailing, 10)
                    Text("반드시 본인 명의의 이메일을 입력해주세요.")
                }
                
                HStack(spacing: 0) {
                    Text("•")
                        .padding(.trailing, 10)
                    Text("본 이메일은 계정 분실 시 아이디 및 비밀번호 찾기, 개인정보 관련 주요 공지사항 안내 등에 사용됩니다.")
                }
            }
            .customFontStyle(size: 14, color: .gray8)
            .multilineTextAlignment(.leading)
            
            Spacer()
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, -40)
                .frame(height: 1)
                .foregroundStyle(Color.gray6)
            
            Spacer().frame(height: 32)
            
            FullWidthButton(
                isEnable: .constant(true),
                buttonText: "저장") {
                    DLog("비밀번호 변경 저장 탭")
                    viewModel.checkEmail()
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
}

#Preview {
    AppDIContainer.makeEditEmailView()
}
