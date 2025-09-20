//
//  WithdrawalView.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI

struct WithdrawalView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var editVersionNickname: String = ""
    
    @StateObject var viewModel: WithdrawalViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)
            
            NavigationBackButtonView(title: "회원 탈퇴") {
                dismiss()
            }
            
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 36)
            
            Text("계정 이메일")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)
            
            let email = obfuscateEmail(UserDefaultsManager.shared.getEmail())
            Text(email)
                .customFontStyle(size: 16, color: .anipickBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 20)
                .padding(16)
                .background(Color.gray5)
                .cornerRadius(8)
                .multilineTextAlignment(.leading)
            
            Spacer().frame(height: 56)
            
            Text("탈퇴 시 주의사항")
                .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)
            
            Text("탈퇴 시, 회원정보는 당사의 개인정보처리방침에 따라 삭제 또는 격리하여 보존 조치되며, 삭제된 데이터는 복구가 불가능합니다. 서비스 내에서 남긴 리뷰는 탈퇴 후에 자동 삭제되지 않습니다.")
                .customFontStyle(size: 14, color: .gray8)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)
            
            Text("‘회원탈퇴’를 누르는 것은 상기 안내사항을 모두 확인하였으며 이에 동의함을 의미합니다.")
                .customFontStyle(size: 12, color: .point)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, -40)
                .frame(height: 1)
                .foregroundStyle(Color.gray6)
            
            Text("정말로 탈퇴하시겠습니까?")
                .customFontStyle(size: 16, color: .anipickPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
            
            
            FullWidthButton(
                isEnable: .constant(true),
                buttonText: "탈퇴하기") {
                    DLog("탈퇴하기 탭탭")
                    self.viewModel.tappedWithdrawal()
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
    AppDIContainer.makeWithdrawalView()
}
