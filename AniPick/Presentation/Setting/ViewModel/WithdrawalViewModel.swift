//
//  WithdrawalViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI
import Alamofire

final class WithdrawalViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var isEnableWithdrawalButton: Bool = false
    
    func tappedWithdrawal() {
        AF.request(SettingAPI.withdrawal)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("withdrawal success - \(value)")
                    if value.code == 200 {
                        self.navigationManager.popToRoot()
                        self.navigationManager.push(route: .mainLoginView)
                        // TODO: User정보 전부 clear하는 값 필요
                        UserDefaultsManager.shared.setAccessToken(accessToken: "")
                        UserDefaultsManager.shared.setRefreshToken(refreshToken: "")
                        UserDefaultsManager.shared.setNickname("")
                    }
                case .failure(let error):
                    DLog("withdrawal error - \(error)")
                }
                
            }
    }
    
}
