//
//  LikeAnimeListViewModel.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

final class LikeAnimeListViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var isEmptyLikeAnime: Bool = true
    @Published var isEmptyLikePerson: Bool = true
}
