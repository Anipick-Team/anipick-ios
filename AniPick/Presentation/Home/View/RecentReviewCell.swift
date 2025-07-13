//
//  Untitled.swift
//  AniPick
//
//  Created by cho on 5/18/25.
//

import SwiftUI

struct RecentReviewCell: View {
    
    @State private var starRating: Double = 0
    @State private var isShowBlockMenu: Bool = false
    
    let id: Int
    let onReportButtonTapped: (_ id: Int, _ buttonFrame: CGRect) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0 ) {
                Rectangle()
                    .frame(width: 80, height: 64)
                    .foregroundStyle(Color.gray)
                    .cornerRadius(8)
                    .padding(.trailing, 16)
                
                // TODO: animation name
                Text("던전밥")
                    .font(.system(size: 16))
                    .foregroundStyle(.anipickBlack)
                
                Spacer()
            }
            
            Rectangle()
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.gray7)
                .padding(.vertical, 19)
            
            HStack(alignment: .center, spacing: 0) {
                StarRatingComponentView(starRating: self.starRating)
                
                Spacer()
                
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.gray)
                    .padding(.trailing, 8)
                
                // TODO: 닉네임 넣어야함!
                Text("차라투스투라")
                    .foregroundStyle(.anipickBlack)
                    .font(.system(size: 12))
                
            }
            
            // TODO: 리뷰 쓴 날짜 넣어야함
            Text("2025.04.12")
                .foregroundStyle(.gray6)
                .font(.system(size: 12))
            
            
            
            Spacer().frame(height: 16)
            
            Text("비아징잔걸삽에 경느삼븐을 아되거비고검에 해가각섬을 미허윤젼이 인논덜더훝고 흑지해다. 지앻개누언 뉘우는 빠디헤지조차, 저뮤라에서 리그한석, 란눨링자를 즈카는. 찬컨옽등이다 고졑뎌졀으로, 숻납모할에 개잔 유짙서다 온근도 여레엡니다 요러주인다 아운은 시재. 긴에우존 논베너까로 기닽아당을 민릈좌명 구잉아를과 사셜엎지에 업워리의. 슳귰크서 버느개어동아 닉오고 아더어 둥뵤이려 춀버를 예슁오송카이어 임븝지엠 운자익이 앤아")
                .lineLimit(2)
                .font(.system(size: 16))
                .foregroundStyle(.anipickBlack)
                .padding(.bottom, 4)
            
            Button {
                DLog("더보기 버튼 탭탭")
            } label: {
                HStack(alignment: .center, spacing: 0) {
                    Text("더보기")
                        .font(.system(size: 14))
                        .foregroundStyle(.anipickPrimary)
                        .padding(.trailing, 4)
                    
                    Image(.chevronDownPrimary)
                }
            }
            
            Spacer().frame(height: 20)
            
            HStack(alignment: .center, spacing: 0) {
                Button {
                    DLog("좋아요 버튼 탭탭, 누를때 fill, unfill heart로 변경되어야함")
                } label: {
                    Image(.unfilledHeart)
                        .padding(.trailing, 4)
                }
                
                // TODO: 좋아요 갯수 넣어야함
                Text("1")
                    .foregroundStyle(.gray6)
                    .font(.system(size: 14))
                
                Spacer()
                
                
                GeometryReader { proxy in
                    Button {
                        let frame = proxy.frame(in: .global)
                        onReportButtonTapped(id, frame)
                        DLog("되었음요 탭탭")
                    } label: {
                        Image(.moreVerticalGray)
                    }
                    .frame(width: 20, height: 20)
                }
                .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(.white)
        .cornerRadius(8)
    }
    
}

//#Preview {
//    RecentReviewCell()
//}
