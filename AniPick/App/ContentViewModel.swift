//
//  ContentViewModel.swift
//  AniPick
//
//  Created by cho on 7/17/25.
//

import SwiftUI

final class ContentViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    @Published var activeTab: Tab = .home
    
    init(activeTab: Tab, navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        self.activeTab = activeTab
    }
    
}
