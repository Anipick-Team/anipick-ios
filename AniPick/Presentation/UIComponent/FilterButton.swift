//
//  FilterButton.swift
//  AniPick
//
//  Created by cho on 5/12/25.
//

import SwiftUI

enum FilterButtonState: String {
    case notSelected
    case selecting
    case selected
    
    var textColor: Color {
        switch self {
        case .notSelected, .selecting:
            return .anipickBlack
        case .selected:
            return .anipickSecondary
        }
    }
    
    var strokeColor: Color {
        switch self {
        case .notSelected:
            return .gray5
        case .selecting, .selected:
            return .anipickSecondary
        }
    }
    
    var chevronImage: Image {
        switch self {
        case .notSelected:
            return Image(.chevronDownGray)
        case .selecting:
            return Image(.chevronUpBlue)
        case .selected:
            return Image(.chevronDownBlue)
        }
    }
}

struct FilterButton: View {
    
    var title: String
    var selectedState: FilterButtonState
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundStyle(selectedState.textColor)
                        .padding(.trailing, 8)
                    
                    selectedState.chevronImage
                    
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(selectedState.strokeColor)
            )
        }
    }
}

#Preview {
    FilterButton(title: "장르", selectedState: .notSelected) {
        DLog("장르 탭탭")
    }
    FilterButton(title: "장르", selectedState: .selecting) {
        DLog("장르 탭탭")
    }
    FilterButton(title: "장르", selectedState: .selected) {
        DLog("장르 탭탭")
    }
}
