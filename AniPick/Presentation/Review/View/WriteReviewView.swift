//
//  WriteReviewView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct WriteReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var starRating: Int = 3
    
    @State private var reviewTextString: String = ""
    var placeholder: String = "리뷰 내용을 입력해주세요."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "리뷰 작성") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 24)
            
            ZStack {
                Rectangle()
                    .frame(height: 123)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    .foregroundColor(.gray7)
                
                
                VStack(alignment: .center, spacing: 0) {
                    self.starView(starRating: 3)
                        .padding(.bottom, 16)
                    
                    Text("(\(self.starRating)/5.0)")
                        .customFontStyle(size: 20, color: .gray6, weight: .bold)
                }
            }
            .padding(.bottom, 12)
            
            // TODO: 스포일러 토글 값 필요
            HStack(spacing: 0) {
                Spacer()
                Text("스포일러")
                    .customFontStyle(size: 16, color: .anipickSecondary, weight: .bold)
                
                Image(.toggleEnable)
            }
            .padding(.bottom, 18)
        
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 215)
                    .foregroundColor(.gray5)
                
                ClearTextEditor(text: $reviewTextString)
                    .frame(height: 140)
                    .customFontStyle(size: 16, color: .gray8)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .background(Color.clear)
                
                if reviewTextString.isEmpty {
                    Text(placeholder)
                        .customFontStyle(size: 16, color: .gray8)
                        .padding(.horizontal, 22)
                        .padding(.top, 22)
                    
                }
                // 글자 수 표시
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(reviewTextString.count)/200")
                            .customFontStyle(size: 14, color: .gray8)
                            .padding([.trailing, .bottom], 12)
                    }
                }
            }
            .frame(height: 215)
            
            Spacer().frame(height: 16)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("주의사항")
                    .padding(.bottom, 8)
                    .customFontStyle(size: 16, color: .gray8, weight: .semibold)
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    Text("커뮤니티 가이드라인 위반 시 게시물이 삭제되며 서비스 이용이 일정기간 제한되거나 영구적으로 제한될 수 있습니다.")
                        .customFontStyle(size: 12, color: .gray8, weight: .semibold)
                        .lineLimit(2)

                    Text("•  악의적인 욕설, 비방, 혐오 표현 등 타인에게 불쾌감을 줄 수 있는 내용")
                    Text("•  스포일러 체크 없이 스포일러를 포함한 리뷰")
                    
                    Text("    (※ 에피소드 내용 요약, 결말 노출 등)")

                    Text("•  광고, 홍보, 도배 등 리뷰 목적과 무관한 내용")

                    Text("•  음란물, 성적 수치심을 유발하는 내용")
     
                    Text("•  기타 커뮤니티 가이드라인 운영 정책에 위반되는 내용")
                }
                .customFontStyle(size: 12, color: .gray8, weight: .semibold)
            }
            .foregroundColor(.gray8)
            
            Button {
                DLog("커뮤니티 가이드라인 웹뷰로 이동")
            } label: {
                Text("커뮤니티 가이드라인 전체보기")
                    .customFontStyle(size: 12, color: .white, weight: .semibold)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 8)
                    .frame(height: 30)
                    .background(Color.gray8)
                    .cornerRadius(8)
                
            }
            .padding(.top, 8)
            
            
            Spacer()
            
            
            FullWidthButton(isEnable: .constant(true), buttonText: "리뷰 작성하기") {
                DLog("리뷰 작성 탭탭")
            }
            .padding(.bottom, 20)
            
            
            
            
            
            
        }
        .padding(.horizontal, 20)
    }
    
    // TODO: 0.5점도 체크 가능하게 만들기 -> 만들어둔거 있음,,,,교체하기
    private func starView(starRating: Int) -> some View {
        return HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { starIdx in
                Button {
                    self.starRating = starIdx
                } label: {
                    Image(starIdx <= self.starRating ? .fillPickStar : .unfillStar)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                .padding(.trailing, 4)
                
            }
        }
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
    WriteReviewView()
}
