//
//  PersonDetailViewModel.swift
//  AniPick
//
//  Created by cho on 9/7/25.
//

import SwiftUI
import Alamofire

final class PersonDetailViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let animeId: Int
    
    @Published var castList: [CharacterAndVoiceActorInfo] = []
    
    let session = Session(interceptor: TokenInterceptor.shared)
    
    init(navigationManager: NavigationManager, animeId: Int) {
        self.navigationManager = navigationManager
        self.animeId = animeId
        self.fetchCharacterAndVoiceActor(animeId: animeId)
    }
    
    func fetchCharacterAndVoiceActor(animeId: Int) {
        session.request(
            AnimeAPI.charactersDetailInfo(
                animeId: self.animeId,
                lastId: nil,
                lastValue: nil,
                size: 20
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: CharacterAndVoiceActorResponse.self) { response in
            switch response.result {
            case .success(let value):
                DLog("fetch character And Detail Info success - \(value)")
                self.castList = value.result.characters
            case .failure(let error):
                DLog("fetch character And Detail Info error - \(error)")
            }
        }
    }
    

    
    func moveToVoiceActorView(personId: Int) {
        self.navigationManager.push(route: .voiceActorDetail(animeId: personId))
    }
}
