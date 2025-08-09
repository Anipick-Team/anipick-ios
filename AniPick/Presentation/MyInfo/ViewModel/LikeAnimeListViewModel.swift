//
//  LikeAnimeListViewModel.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI
import Alamofire

final class LikeAnimeListViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var isEmptyLikeAnime: Bool = true
    @Published var isEmptyLikePerson: Bool = true
    @Published var lastId: Int? = nil
    @Published var animeList: [LikedAnime] = []
    @Published var count: Int = 0
    let session = Session(interceptor: TokenInterceptor.shared)
}

extension LikeAnimeListViewModel {
    func fetchLikeAnimeList() {
        session.request(MyInfoAPI.likedAnimeList(lastId: self.lastId, size: 20))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: MyInfoLikedAnimeResposne.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("MyInfo - Liked Anime List  - \(value)")
                    if let result = value.result,
                       let animeList = result.animes {
                        self.animeList = animeList
                        self.lastId = result.cursor?.lastId
                        self.count = result.count
                        
                    }
                case .failure(let error):
                    DLog("MyInfo - Liked Anime List error  - \(error)")
                }
            }
    }

}


