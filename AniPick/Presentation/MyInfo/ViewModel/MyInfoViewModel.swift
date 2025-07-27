//
//  MyInfoViewModel.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI
import Alamofire

final class MyInfoViewModel: ObservableObject {
    
    @Published var myInfoProfileData: UserProfile?
    @Published var watchListCount: Int = 0
    @Published var watchingCount: Int = 0
    @Published var finishedCount: Int = 0
    @Published var likedAnimeList: [LikedAnime] = []
    @Published var likedPersonList: [LikedPerson] = []
    
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var isEmptyLikeAnime: Bool = true
    @Published var isEmptyLikePerson: Bool = true
}

extension MyInfoViewModel {
    func tappedToWatchList() {
        self.navigationManager.push(route: .myInfoInToWatchList)
    }
    
    func tappedSettingButton() {
        self.navigationManager.push(route: .setting)
    }
}

extension MyInfoViewModel {
    func fetchMyInfo() {
        AF.request(MyInfoAPI.myInfo)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .response { response in
                print("응답 상태 코드: \(response.response?.statusCode ?? 0)")
                if let data = response.data, !data.isEmpty {
                    print("응답 내용: \(String(data: data, encoding: .utf8) ?? "디코딩 실패")")
                } else {
                    print("📭 응답 본문이 없음")
                }
            }
            .responseDecodable(of: MyInfoResponse.self) { response in
                switch response.result {
                case .success(let value):
                    if let data = value.result {
                        if let watchs = data.watchCounts {
                            self.watchingCount = watchs.watching ?? 0
                            self.watchListCount = watchs.watchList ?? 0
                            self.finishedCount = watchs.finished ?? 0
                            self.likedAnimeList = data.likedAnimes ?? []
                        }
                }
                    print("✅ 성공: \(value)")
                case .failure(let error):
                    print("❌ 실패: \(error)")
                }
            }
    }
}
