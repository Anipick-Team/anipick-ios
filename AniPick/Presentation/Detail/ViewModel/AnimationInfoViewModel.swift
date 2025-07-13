//
//  AnimationInfoViewModel.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

final class AnimationInfoViewModel: ObservableObject {
    @Published var isShowSortOptionView: Bool = false
    @Published var isShowOnlyReview: Bool = false
}
