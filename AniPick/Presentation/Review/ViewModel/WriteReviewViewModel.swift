//
//  WriteReviewViewModel.swift
//  AniPick
//
//  Created by cho on 7/15/25.
//

import SwiftUI
import Alamofire

final class WriteReviewViewModel: ObservableObject {
    
    @Published var reviewTextContent: String = ""
    @Published var starRating: Double = 0
    @Published var isSpoiler: Bool = false
    @Published var animeId: Int = 0
    @Published var isFirstVisit: Bool = true
    let session = Session(interceptor: TokenInterceptor.shared)
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager, starRating: Double, animeId: Int, reviewContent: String) {
        self.navigationManager = navigationManager
        self.starRating = starRating
        self.animeId = animeId
        self.reviewTextContent = reviewContent
        if reviewContent.isEmpty == false {
            self.isFirstVisit = false
        }
    }
}

extension WriteReviewViewModel {
    func patchReview() {
        session.request(
                AnimeAPI.writeAndEditReview(
                    animeId: self.animeId,
                    content: self.reviewTextContent,
                    rating: self.starRating,
                    isSpoiler: self.isSpoiler
                )
            )
        .cURLDescription { description in
            DLog("\(description)")
            
        }
        .responseDecodable(of: BaseResponse.self) { [weak self] response in
            guard let self else { return }
            switch response.result {
            case .success(let value):
                DLog("리뷰 성공성공 - \(value)")
                AnalyticsManager.logReviewWrite(animeId: self.animeId, rating: self.starRating, isSpoiler: self.isSpoiler)
                NotificationCenter.default.post(
                    name: .reloadRatedAnime,
                    object: nil
                )
            case .failure(let error):
                DLog("리이뷰 실패 - \(error)")
                AnalyticsManager.logError(error, context: "patchReview")
            }
            
        }
    }
    
    func pop() {
        self.navigationManager.pop()
    }
    
    func toggleSpoiler() {
        self.isSpoiler.toggle()
    }
    
//    func moveToWriteReview(starRating: Double, reviewContent: String) {
//        self.navigationManager.push(route: .review(starRating: starRating, animeId: self.animeId, reviewContent: reviewContent))
//    }
}
