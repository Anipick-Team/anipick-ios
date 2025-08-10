//
//  SettingViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI
import Alamofire

final class SettingViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    @Published var newNickname: String = ""
    @Published var isShowLogoutPopup: Bool = false
    
    @Published var nickname: String = ""
    @Published var email: String = ""
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
     func moveToDetailSettingView(route: AppRoute) {
        navigationManager.push(route: route)
    }
    
    func tappedLogout() {
        AF.request(LogoutAPI.logout)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("logout success - \(value)")
                    self.navigationManager.popToRoot()
                    self.navigationManager.push(route: .mainLoginView)
                case .failure(let error):
                    DLog("logout error - \(error)")
                }
                
            }
    }
 
    func tappedWithdrawal() {
        AF.request(SettingAPI.withdrawal)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("withdrawal success - \(value)")
                    self.navigationManager.popToRoot()
                    self.navigationManager.push(route: .mainLoginView)
                    // TODO: User정보 전부 clear하는 값 필요
                    UserDefaultsManager.shared.setAccessToken(accessToken: "")
                    UserDefaultsManager.shared.setRefreshToken(refreshToken: "")
                    UserDefaultsManager.shared.setNickname("")
                case .failure(let error):
                    DLog("withdrawal error - \(error)")
                }
                
            }
    }
    
    func resetData() {
        self.nickname = UserDefaultsManager.shared.getNickname()
        self.email = UserDefaultsManager.shared.getEmail()
    }
    
    func actionBySettingCategory(category: SettingCategory) {
        switch category {
        case .editNickname:
            self.moveToDetailSettingView(route: .editNickname)
        case .editEmail:
            self.moveToDetailSettingView(route: .editEmail)
        case .editPassword:
            self.moveToDetailSettingView(route: .editPassword)
        case .linkedSNS:
            DLog("sns임!!")
        case .appVersion:
            DLog("AppVersion")
        case .inquiry:
            DLog("문의하기 웹뷰로 이동")
            let url = URL(string: "https://forms.gle/SJ7mbQfyfoe2HDLd7")!
            UIApplication.shared.open(url)
        case .termsOfService:
            let url = URL(string: "https://spiral-cowl-f89.notion.site/AniPick-1d3b3eed42088025b329eb107cd42ae1?source=copy_link")!
            UIApplication.shared.open(url)
        case .privacyPolicy:
            let url = URL(string: "https://spiral-cowl-f89.notion.site/AniPick-1d3b3eed42088077a175f63a04dc93fd?source=copy_link")!
            UIApplication.shared.open(url)
        case .notice:
            let url = URL(string: "https://spiral-cowl-f89.notion.site/227b3eed42088098a351ff047659bdcb?source=copy_link")!
            UIApplication.shared.open(url)
        case .logout:
            self.isShowLogoutPopup = true
        case .deleteAccount:
            DLog("탈퇴 APIAPI")
            self.tappedWithdrawal()
        }
        
    }
    
 
}
