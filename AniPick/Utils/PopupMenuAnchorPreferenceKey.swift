//
//  PopupMenuAnchorPreferenceKey.swift
//  AniPick
//
//  Created by cho on 11/26/25.
//

import SwiftUI

struct PopupMenuAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}
