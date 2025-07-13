//
//  PreferenceSelectionViewModel.swift
//  AniPick
//
//  Created by cho on 6/18/25.
//

import SwiftUI

final class PreferenceSelectionViewModel: ObservableObject {
    
    @Published var keywordAnime: [AnimeResult] = []
    
    private let searchUsecase: SearchUsecaseProtocol
    
    init(searchUsecase: SearchUsecaseProtocol) {
        self.searchUsecase = searchUsecase
    }
}

extension PreferenceSelectionViewModel {
   
}
