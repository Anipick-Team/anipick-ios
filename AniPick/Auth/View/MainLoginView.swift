//
//  MainLoginView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct MainLoginView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("AniPickLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
            
            Spacer()
                .frame(height: 48)
            
            VStack(spacing: 0) {
                Text("나에게 딱 맞는 애니 추천을 위해.")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.bottom, 8)
                Text("사용할수록 더 좋아지는 애니메이션 환경을 만나보세요")
                    .font(.system(size: 14))
            }
            .padding(.bottom, 60)
            
            
            // TODO: 각각 로그인 버튼으로 수정
            // TODO: kakao
            Rectangle()
                .frame(width: 362, height: 64)
                .foregroundStyle(Color.yellow)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // TODO: google
            Rectangle()
                .frame(width: 362, height: 64)
                .foregroundStyle(Color.gray)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // TODO: apple
            Rectangle()
                .frame(width: 362, height: 64)
                .foregroundStyle(Color.black)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            
            HStack(spacing: 0) {
                Button {
                    // TODO: 이메일 회원가입 이동
                } label: {
                    Text("이메일 회원가입")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                }
                
                Rectangle()
                    .frame(width: 1, height: 15)
                    .foregroundStyle(Color.gray)
                    .padding(.horizontal, 10)
                
                Button {
                    // TODO: 이메일 로그인 이동
                } label: {
                    Text("이메일 로그인")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                }
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 21)
                .stroke(Color.gray, lineWidth: 1)
                .frame(width: 190, height: 30)
                .foregroundStyle(Color.white)
                .overlay {
                    Text("로그인에 문제가 있으신가요?")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                }
                .padding(.bottom, 50)
            
            
            
        }
    }
}


#Preview {
    MainLoginView()
}
