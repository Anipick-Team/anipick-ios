//
//  MyInfoView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct MyInfoView: View {
    var body: some View {
        NavigationStack {
                    List {
                        // 계정 섹션
                        Section(header: Text("계정")) {
                            settingsRow(title: "닉네임 변경", rightText: "동당동당")
                            settingsRow(title: "이메일 변경", rightText: "1234@gmail.com")
                            settingsRow(title: "비밀번호 변경", showChevron: true)
                            settingsRow(title: "연동 SNS", rightText: "카카오톡", rightTextColor: .green)
                        }

                        // 앱 설정 섹션
                        Section(header: Text("앱 설정")) {
                            settingsRow(title: "앱 버전", rightText: "1.0", showChevron: false)
                            settingsRow(title: "문의하기", showChevron: true)
                            settingsRow(title: "서비스 이용약관", showChevron: true)
                            settingsRow(title: "개인정보 처리방침", showChevron: true)
                            settingsRow(title: "공지사항", showChevron: true)
                        }

                        // 기타 섹션
                        Section(header: Text("기타")) {
                            settingsRow(title: "로그아웃", rightTextColor: .red, isDestructive: true)
                            settingsRow(title: "회원 탈퇴", rightTextColor: .red, isDestructive: true)
                        }
                    }
                    .navigationTitle("설정")
                    .navigationBarTitleDisplayMode(.inline)
                }
    }
    
    @ViewBuilder
       private func settingsRow(
           title: String,
           rightText: String? = nil,
           rightTextColor: Color = .gray,
           showChevron: Bool = true,
           isDestructive: Bool = false
       ) -> some View {
           HStack {
               Text(title)
                   .foregroundColor(isDestructive ? .red : .primary)
               Spacer()
               if let rightText {
                   Text(rightText)
                       .foregroundColor(isDestructive ? .red : rightTextColor)
                       .font(.subheadline)
               }
               if showChevron {
                   Image(systemName: "chevron.right")
                       .foregroundColor(.gray)
                       .font(.system(size: 12))
               }
           }
           .padding(.vertical, 8)
       }
}

#Preview {
    MyInfoView()
}
