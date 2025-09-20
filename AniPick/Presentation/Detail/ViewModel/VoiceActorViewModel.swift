//
//  VoiceActorViewModel.swift
//  AniPick
//
//  Created by cho on 9/5/25.
//

import SwiftUI
import Alamofire

final class VoiceActorViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let animeId: Int
    
    let session = Session(interceptor: TokenInterceptor.shared)
    
    @Published var actorImageUrl: String = ""
    @Published var actorName: String = ""
    @Published var workCount: Int = 0
    @Published var workList: [PersonWork] = []
    @Published var isLiked: Bool = false
    var lastId: Int? = nil
    
    init(navigationManager: NavigationManager, animeId: Int) {
        self.navigationManager = navigationManager
        self.animeId = animeId
        self.fetchVoiceActorInfo(personId: animeId)
    }
}

extension VoiceActorViewModel {
    func fetchVoiceActorInfo(personId: Int) {
        session.request(AnimeAPI.voiceActorDetailInfo(personId: personId, lastId: self.lastId, size: 20))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: PersonDetailResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("fetch voice Actor Info success - \(value)")
                    self.actorImageUrl = value.result.profileImageUrl ?? ""
                    self.actorName = value.result.name
                    self.workCount = value.result.count
                    self.workList.append(contentsOf: value.result.works)
                    self.isLiked = value.result.isLiked
                    self.lastId = value.result.cursor.lastId
                    
                case .failure(let error):
                    DLog("fetch voice Actor Info error - \(error)")
                }
            }
    }
    
    func fetchNextPage(item: Int) {
        if item == self.workList.last?.characterId {
            self.fetchVoiceActorInfo(personId: self.animeId)
        }
    }
    
    func likePerson() {
        // TODO: animeId가 아닌 personId임. 이름 변경 필요
        session.request(AnimeAPI.likePerson(personId: self.animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("fetch person like success - \(value)")
                case .failure(let error):
                    DLog("fetch person like error - \(error)")
                }
            }
    }
    
    func cancelLikePerson() {
        // TODO: animeId가 아닌 personId임. 이름 변경 필요
        session.request(AnimeAPI.cancelLikePerson(personId: self.animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("fetch person cancel like success - \(value)")
                case .failure(let error):
                    DLog("fetch person cancel like error - \(error)")
                }
            }
    }
}
