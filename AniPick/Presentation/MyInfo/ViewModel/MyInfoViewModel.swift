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
    @Published var likedPersonList: [LikedRatedPerson] = []
    
    @Published var toWatchList: [ToWatchAnime] = []
    @Published var toWatchListCount: Int = 0
    
    @Published var watchingList: [ToWatchAnime] = []
    @Published var watchingListCount: Int = 0
    
    @Published var finishedList: [ToWatchAnime] = []
    @Published var finishedListCount: Int = 0
    
    let session = Session(interceptor: TokenInterceptor.shared)
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var isEmptyLikeAnime: Bool = true
    @Published var isEmptyLikePerson: Bool = true
    
    var watchlistLastId: Int? = nil
    var watchingListLastId: Int? = nil
    var likedPersonLastId: Int? = nil
}

extension MyInfoViewModel {
    func tappedToWatchList() {
        self.navigationManager.push(route: .myInfoInToWatchList)
    }
    
    func tappedToWatchingList() {
        self.navigationManager.push(route: .myInfoWatchingList)
    }
    
    func tappedToFinishedAnimeList() {
        self.navigationManager.push(route: .finishedWatchList)
    }
    
    func tappedSettingButton() {
        self.navigationManager.push(route: .setting)
    }
}

extension MyInfoViewModel {
    func fetchMyInfo() {
        session.request(MyInfoAPI.myInfo)
            .cURLDescription { description in
                DLog("\(description)")
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
                    DLog("✅ 성공: \(value)")
                case .failure(let error):
                    DLog("❌ 실패: \(error)")
                }
            }
    }
    
    func fetchLikePersonList() {
        session.request(MyInfoAPI.likedPersonList(lastId: self.likedPersonLastId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: LikedPersonListResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("fetch person list success - \(value)")
                    self.likedPersonList = value.result.persons
                    self.likedPersonLastId = value.result.cursor.lastId
                case .failure(let error):
                    DLog("fetch person list error - \(error)")
                }
            }
        
    }
    
    func fetchToWatchList() {
        session.request(MyInfoAPI.toWatchAnimeList(status: "WATCHLIST", lastId: watchlistLastId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ToWatchResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("✅ 성공: \(value)")
                    self.toWatchListCount = value.result.count
                    self.toWatchList = value.result.animes ?? []
                case .failure(let error):
                    DLog("❌ 실패: \(error)")
                }
            }
    }
    
    
    func fetchWatchingList() {
        session.request(MyInfoAPI.watchingAnimeList(status: "WATCHING", lastId: self.watchlistLastId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ToWatchResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("✅ 성공: \(value)")
                    self.watchingListCount = value.result.count
                    self.watchingList = value.result.animes ?? []
                case .failure(let error):
                    DLog("❌ 실패: \(error)")
                }
            }
    }
    
    
    
    func fetchFinishedList() {
        session.request(MyInfoAPI.watchingAnimeList(status: "FINISHED", lastId: self.watchlistLastId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ToWatchResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("✅ 성공: \(value)")
                    self.finishedListCount = value.result.count
                    self.finishedList = value.result.animes ?? []
                case .failure(let error):
                    DLog("❌ 실패: \(error)")
                }
            }
    }
    
    // TODO: profile 이미지 업로드 하는 것 정리 필요
    func editProfimeImage(image: UIImage) {
        let request = ProfileAPI.editProfileImage(image: image)
        session.upload(multipartFormData: { multidata in
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Failed to convert image to data")
                return
            }
            
            multidata.append(imageData, withName: "profileImageFile", fileName: "profile.jpg", mimeType: "image/jpeg")
        }, to: request.path, method: request.method)
        .response { response in
            switch response.result {
            case .success(let data):
                print("Image uploaded successfully: \(String(describing: data))")
            case .failure(let error):
                print("Failed to upload image: \(error.localizedDescription)")
            }
        }
    }
    
    func getProfileImage(completion: @escaping (Image?) -> Void) {
        let imageId = UserDefaultsManager.shared.getImageId()
      //  session.request(MyInfoAPI.getProfileImage(imageId: imageId))
        session.request(MyInfoAPI.getProfile(imageId: imageId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .response { response in
                switch response.result {
                case .success(let data):
                    DLog("profile Image get successfully: \(String(describing: data))")
                    if let data = data, let uiImage = UIImage(data: data) {
                        let swiftUIImage = Image(uiImage: uiImage)  // UIImage를 Image로 변환
                        completion(swiftUIImage)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    DLog("Failed to get profile image: \(error.localizedDescription)")
                }
            }
    }
    
    func moveToLikedAnimeListView() {
        self.navigationManager.push(route: .likeAnimeList)
    }
    
    func moveToRatedAnimeListView() {
        self.navigationManager.push(route: .ratedAnimeList)
    }
    
    func moveToDetailAnime(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
    
    func moveToLikedPersonListView() {
        self.navigationManager.push(route: .likePersonList)
    }
}
