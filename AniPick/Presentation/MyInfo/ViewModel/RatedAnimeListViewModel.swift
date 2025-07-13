//
//  RatedAnimeListViewModel.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

final class RatedAnimeListViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var isShowOnlyReview: Bool = false
    @Published var isShowSortOptionView: Bool = false
}
