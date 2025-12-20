//
//  WriteReviewView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct WriteReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: WriteReviewViewModel
    
    @State private var ratedStar: Double = 0.0
    
    var placeholder: String = "리뷰 내용을 입력해주세요."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: self.viewModel.isFirstVisit ? "리뷰 작성" : "리뷰 수정") {
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
                    StarRatingComponentView(
                        starRating: viewModel.starRating,
                        fontSize: 20,
                        fontColor: .gray6,
                        starSize: 32
                    ) { star in
                        self.viewModel.starRating = star
                    }
                }
            }
            .padding(.bottom, 12)
            
            // TODO: 스포일러 토글 값 필요
            Button {
                viewModel.toggleSpoiler()
            } label: {
                HStack(spacing: 0) {
                    Spacer()
                    Text("스포일러")
                        .customFontStyle(size: 16, color: .anipickSecondary, weight: .bold)
                    Button {
                        self.viewModel.isSpoiler.toggle()
                    } label: {
                        Image(viewModel.isSpoiler ? .toggleEnable : .toggleDisable)
                    }
                }
                .padding(.bottom, 18)
            }
        
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 215)
                    .foregroundColor(.gray5)
                
                ClearTextEditor(text: $viewModel.reviewTextContent)
                    .frame(height: 140)
                    .customFontStyle(size: 16, color: .anipickBlack)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .background(Color.clear)
                
                if viewModel.reviewTextContent.isEmpty {
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
                        Text("\(viewModel.reviewTextContent.count)/200")
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
                let url = URL(string: "https://anipick.p-e.kr/community-guidelines.html")!
                UIApplication.shared.open(url)
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
            
            FullWidthButton(isEnable: .constant(true), buttonText: self.viewModel.isFirstVisit ? "리뷰 작성하기" : "리뷰 수정하기") {
                DLog("리뷰 작성 탭탭")
                viewModel.patchReview()
                viewModel.pop()
            }
            .padding(.bottom, 20)

        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 20)
        .background(Color.white)
        .onTapGesture {
            UIApplication.shared.endEditing()
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
    AppDIContainer.makeReviewView(starRating: 3.7, animeId: 123, reviewContent: "asdfa")
}
