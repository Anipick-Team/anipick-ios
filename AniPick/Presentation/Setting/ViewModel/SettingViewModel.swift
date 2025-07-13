//
//  SettingViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI

final class SettingViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    func moveToDetailSettingView(route: AppRoute) {
        navigationManager.push(route: route)
    }
}
