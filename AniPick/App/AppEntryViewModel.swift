//
//  AppEntryViewModel.swift
//  AniPick
//
//  Created by cho on 7/19/25.
//

import SwiftUI
import Alamofire

@MainActor
final class AppEntryViewModel: ObservableObject {
    private let session = NetworkSession.authenticated
    
    func checkVersion() {
        session.request(VersionAPI.checkVersion)
            .cURLDescription { DLog($0) }
            .responseDecodable(of: VersionResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("version check success - \(value)")
                case .failure(let error):
                    DLog("version check에서 error 발생 - \(error)")
                }
            }
    }
    
    func fetchMataData(retryCount: Int = 3) {
        session.request(MetaDataAPI.metaData)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: MetaDataResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("meta data fetch 성공 - \(value)")
                    let seasonYear = value.result?.seasonYear ?? []
                    let animeType = value.result?.type ?? []
                    let genres = value.result?.genres ?? []
                    let season = value.result?.season ?? []
                    UserDefaultsManager.shared.setMetaDataForSeasonYear(seasonYear)
                    UserDefaultsManager.shared.setMetaDataForType(animeType)
                    UserDefaultsManager.shared.setMetaDataForGenres(genres)
                    UserDefaultsManager.shared.setMetaDataForSeason(season)
                case .failure(let error):
                    DLog("meta data fetch 실패 - \(error)")
                    if retryCount > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.fetchMataData(retryCount: retryCount - 1)
                        }
                    }
                }
            }
    }
}
