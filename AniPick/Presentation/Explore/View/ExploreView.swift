//
//  ExploreView.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import SwiftUI

struct ExploreView: View {
    @StateObject var viewModel: ExploreViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ExploreView")
        }
        .onAppear {
            Task {
                await viewModel.getExploreItems(category: .popularity)
            }
        }
      
    }
}
