//
//  TestView.swift
//  AniPick
//
//  Created by cho on 6/18/25.
//

import SwiftUI

struct TestView: View {
    
    var body: some View {
        ScrollView {
            VStack {
                
                Button("검색 인덱스 조회") {
                    Task {
                        let response = try await SearchAPIService.shared.getSearchResult()
                        DLog("검색 인덱스 조회 - init \(response)")
                    }
                }
                
    
                
                Button("검색 search query") {
                    Task {
                        let response = try await SearchAPIService.shared.getAnimeQueryResult(query: "titan")
                        DLog("검색 search query - init \(response)")
                    }
                }
                
                Button("인물 검색") {
                    Task {
                        let response = try await SearchAPIService.shared.getPersonQueryResult(query: "나츠키")
                        DLog("인물 검색 query - init \(response)")
                    }
                }
                
                Button("제작사 검색") {
                    Task {
                        let response = try await SearchAPIService.shared.getStudioQueryResult(query: "mappa")
                        DLog("제작사 검색 query - init \(response)")
                    }
                }
                
                Button("최근 리뷰 목록") {
                    Task {
                        let response = try await ReviewAPIService.shared.getRecentReviews()
                        DLog("최근 리뷰 - init \(response)")
                    }
                }
                
                Button("리뷰 쪼아욤") {
                    Task {
                        let response = try await ReviewAPIService.shared.likeReview(id: 24)
                        DLog("리뷰 조아여 - init \(response)")
                    }
                }
                
                Button("리뷰 좋아요 취소") {
                    Task {
                        let response = try await ReviewAPIService.shared.cancelReview(id: 24)
                        DLog("리뷰 조아요 취소할게여 - init \(response)")
                    }

                }
                
                Button("리뷰 신고") {
                    Task {
                        let response = try await ReviewAPIService.shared.reportReview(id: 24)
                        DLog("리뷰 신고신고 - init \(response)")
                    }
                }
                
                Button("") {
                
                }
                
                Button("") {
                
                }
                
                Button("") {
                
                }
                
                Button("") {
                
                }
                
                
            }
        }
    }
}
