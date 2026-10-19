//
//  WithdrawalViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI
import Alamofire
import Utils

@MainActor
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
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("withdrawal success - \(value)")
                    if value.code == 200 {
                        // TODO: User정보 전부 clear하는 값 필요
                        UserDefaultsManager.shared.setNickname("")
                        // 토큰 삭제와 로그인 화면 전환은 Session이 맡는다.
                        Task {
                            await AppSession.shared.signOut(.withdrawal)
                        }
                    }
                case .failure(let error):
                    DLog("withdrawal error - \(error)")
                }
                
            }
    }
    
}
