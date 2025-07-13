//
//  ReportReviewWithReasonPopupView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct ReportReviewWithReasonPopupView: View {
    var cancelAction: () -> Void
    var okAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            
            // TODO: 가운데 정렬 필요함
            VStack(spacing: 0) {
                Text("신고하는 사유를 선택해주세요.")
                    .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 8)
                    .padding(.top, 37)

                Text("신고 시, 검토 후 처리되어요.")
                    .customFontStyle(size: 14, color: .settingSubTitle)

                Spacer().frame(height: 34)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        HStack(alignment: .center, spacing: 0) {
                            Image(.unSelectIcon)
                                .resizable()
                                .frame(width: 19, height: 19)
                                .padding(.trailing, 8)
                            
                            Text("스포일러")
                                .customFontStyle(size: 16, color: .anipickBlack)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        
                        HStack(alignment: .center, spacing: 0) {
                            Image(.unSelectIcon)
                                .resizable()
                                .frame(width: 19, height: 19)
                                .padding(.trailing, 8)
                            
                            Text("편파적인 언행")
                                .customFontStyle(size: 16, color: .anipickBlack)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        
                    }
                    .padding(.bottom, 16)
                    
                    
                    HStack(alignment: .center, spacing: 0) {
                        HStack(alignment: .center, spacing: 0) {
                            Image(.unSelectIcon)
                                .resizable()
                                .frame(width: 19, height: 19)
                                .padding(.trailing, 8)
                            
                            Text("욕설 및 비하")
                                .customFontStyle(size: 16, color: .anipickBlack)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        HStack(alignment: .center, spacing: 0) {
                            Image(.unSelectIcon)
                                .resizable()
                                .frame(width: 19, height: 19)
                                .padding(.trailing, 8)
                            
                            Text("홍보성 및 영리 목적")
                                .customFontStyle(size: 16, color: .anipickBlack)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 16)
                    
                    HStack(alignment: .center, spacing: 0) {
                        Image(.unSelectIcon)
                            .resizable()
                            .frame(width: 19, height: 19)
                            .padding(.trailing, 8)
                        
                        Text("음란성 및 선정성")
                            .customFontStyle(size: 16, color: .anipickBlack)
                         Spacer()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 40)
                
                HStack {
                    Button {
                        cancelAction()
                    } label: {
                        Text("취소")
                            .customFontStyle(size: 16, color: .textGray)
                            .frame(maxWidth: .infinity)
                    }

                    Divider()

                    Button {
                        okAction()
                    } label: {
                        Text("신고하기")
                            .customFontStyle(size: 16, color: .anipickPrimary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 22)
                
                Spacer().frame(height: 37)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
}

enum ReportReason: String {
    case spoiler = "스포일러"
    case biasedBehaviro = "편파적인 언행"
    case profanity = "욕설 및 비하"
    case promotional = "홍보성 및 영리 목적"
    case obscenity = "음란성 및 선정성"
}

#Preview {
    ReportReviewWithReasonPopupView {
        DLog("cancel")
    } okAction: {
        DLog("ok")
    }

}
