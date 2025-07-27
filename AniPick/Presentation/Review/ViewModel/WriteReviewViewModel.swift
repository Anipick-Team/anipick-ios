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
    
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager, starRating: Double, animeId: Int) {
        self.navigationManager = navigationManager
        self.starRating = starRating
        self.animeId = animeId
    }
    
}


extension WriteReviewViewModel {
    func patchReview() {
        AF.request(
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
        .responseDecodable(of: BaseResponse.self) { response in
            switch response.result {
            case .success(let value):
                DLog("리뷰 성공성공 - \(value)")
            case .failure(let error):
                DLog("리이뷰 실패 - \(error)")
            }
            
        }
    }
}
