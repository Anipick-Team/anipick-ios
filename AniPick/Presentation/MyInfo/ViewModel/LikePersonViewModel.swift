//
//  LikePersonViewModel.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI
import Alamofire

@MainActor
final class LikePersonViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    private let session = NetworkSession.authenticated
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        self.fetchLikePerson()
    }
    
    @Published var isEmptyLikeAnime: Bool = true
    @Published var isEmptyLikePerson: Bool = true
    
    @Published var likedPersonList: [LikedRatedPerson] = []
    @Published var likedPersonCount: Int = 0
    
    private var lastId: Int? = nil
}

extension LikePersonViewModel {
    func fetchLikePerson() {
        session.request(MyInfoAPI.likedPersonList(lastId: self.lastId))
            .cURLDescription { DLog($0) }
            .responseDecodable(of: LikedPersonListResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("liked person list success - \(value)")
                    self.likedPersonList.append(contentsOf: value.result.persons)
                    self.likedPersonCount = value.result.count
                    self.lastId = value.result.cursor.lastId
                case .failure(let error):
                    DLog("liked person list - \(error)")
                }
            }
    }
    
    func fetchNextPage(personId: Int) {
        if personId == self.likedPersonList.last?.personId {
            self.fetchLikePerson()
        }
    }
    
    func moveToPersonDetailView(personId: Int) {
        self.navigationManager.push(route: .voiceActorDetail(animeId: personId))
    }
}
