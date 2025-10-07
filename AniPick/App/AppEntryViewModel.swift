//
//  AppEntryViewModel.swift
//  AniPick
//
//  Created by cho on 7/19/25.
//

import SwiftUI
import Alamofire

final class AppEntryViewModel: ObservableObject {
    let session = Session(interceptor: TokenInterceptor.shared)
    func checkAuthentication() {
        
    }
    
    
    func fetchMataData() {
        session.request(MetaDataAPI.metaData)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: MetaDataResponse.self) { response in
                switch response.result {
                case .success(let value):
                    // TODO: 성공했으면 userdefatuls 업데이트하는 로직 필요
                    DLog("meta data fetch 성공 - \(value)")
                    let seasonYear = value.result.seasonYear
                    let animeType = value.result.type
                    let genres = value.result.genres
                    let season = value.result.season
                    
                    UserDefaultsManager.shared.setMetaDataForSeasonYear(seasonYear)
                    UserDefaultsManager.shared.setMetaDataForType(animeType)
                    UserDefaultsManager.shared.setMetaDataForGenres(genres)
                    UserDefaultsManager.shared.setMetaDataForSeason(season)
                    
                case .failure(let error):
                    // TODO: 실패했을 떄, 그냥 userdefautls 그대로 사용.
                    DLog("meta data fetch 실패 - \(error)")
                }
            }
    }
}
