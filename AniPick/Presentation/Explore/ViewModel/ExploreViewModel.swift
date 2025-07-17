//
//  ExploreViewModel.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import SwiftUI

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var exploreItems: [Anime] = []
    
    
    private let usecase: ExploreUsecase
    
    init(usecase: ExploreUsecase) {
        self.usecase = usecase
        Task {
            await self.getExploreItems(category: .popularity)
        }
    }
}

extension ExploreViewModel {
    func getExploreItems(category: ExploreSortCategory) async {
        do {
            let response = try await usecase.getExploreAnimes(category: category)
            self.exploreItems = response.result.animes
            DLog("explore Item - \(self.exploreItems)")
        } catch {
            DLog("explore Item error - \(error.localizedDescription)")
        }
    }
}
