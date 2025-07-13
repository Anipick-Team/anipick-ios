//
//  EmailLoginView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct EmailLoginView: View {
    @State private var emailTextString: String = ""
    @State private var passwordTextString: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading) {
                Text("이메일 로그인")
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.bottom, 4)
                
                Text("회원 서비스 이용을 위해 로그인 해주세요.")
                    .font(.system(size: 14, weight: .medium))
            }
            
            Spacer()
                .frame(height: 64)
            
            Text("이메일")
                .font(.system(size: 18, weight: .bold))
                .padding(.bottom, 12)
            
            TextField(
                    "",
                    text: $emailTextString,
                    prompt: Text("이메일을 입력해주세요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textGray)
                )
                .padding(16)
                .background(.textFieldBackground)
                .foregroundStyle(.black)
                .cornerRadius(8)
            
            
           
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        
        
    }
}

#Preview {
    EmailLoginView()
}
