//
//  ExploreViewModel.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import SwiftUI

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var exploreItems: ExploreResult?
    
    
    private let usecase: ExploreUsecase
    
    init(usecase: ExploreUsecase) {
        self.usecase = usecase
    }
}

extension ExploreViewModel {
    func getExploreItems(category: ExploreSortCategory) async {
        do {
            let response = try await usecase.getExploreAnimes(category: category)
            self.exploreItems = response.result
            DLog("explore Item - \(self.exploreItems)")
        } catch {
            DLog("explore Item error - \(error.localizedDescription)")
        }
    }
}
