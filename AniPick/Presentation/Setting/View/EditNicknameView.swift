//
//  EditNicknameView.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI

struct EditNicknameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editVersionNickname: String = ""
    
    @StateObject var viewModel: EditNicknameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)
            
            NavigationBackButtonView(title: "닉네임 변경") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 36)
                        
            Text("기존 닉네임")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)
                
            // TODO: Userdefaults에서 닉네임 가져오기
            Text("동당동당")
                .customFontStyle(size: 16, color: .anipickBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 20)
                .padding(16)
                .background(Color.gray5)
                .cornerRadius(8)
                .multilineTextAlignment(.leading)
                
            Spacer().frame(height: 32)
            
            TextFieldComponents(
                titleText: "새 닉네임",
                placeholderText: "새 닉네임 입력",
                textFieldString: $editVersionNickname
            )
            .padding(.bottom, 12)
            
            // TODO: 이미 사용중인지 확인하는 api 보내는 통신해야함
            if viewModel.isDuplicateNickname {
                Text("이미 사용 중인 닉네임입니다")
                    .customFontStyle(size: 14, color: .point, weight: .semibold)
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
                    DLog("닉네임 변경 저장 액션")
                }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
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
    AppDIContainer.makeEditNicknameView()
}
