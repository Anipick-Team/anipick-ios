//
//  NavigationBackButtonView.swift
//  AniPick
//
//  Created by cho on 6/26/25.
//

import SwiftUI

struct NavigationBackButtonView: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 0) {
                Button {
                    action()
                } label: {
                    Image(.chevronLeft)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding(.leading, 20)
                Spacer()
            }
            
            Spacer()
            
            Text(title)
                .customFontStyle(size: 18, color: .anipickBlack, weight: .black)
            
            Spacer()
        }
    }
}
