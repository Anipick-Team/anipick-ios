//
//  FullWidthButton.swift
//  AniPick
//
//  Created by cho on 5/3/25.
//

import SwiftUI

struct FullWidthButton: View {
    @Binding var isEnable: Bool
    let buttonText: String
    let complectionHandler: () -> Void
    
    var body: some View {
        Button {
            complectionHandler()
        } label: {
            Text(buttonText)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isEnable ? .anipickPrimary : .gray6)
                    .cornerRadius(8)
        }
    }
}

#Preview {
    FullWidthButton(isEnable: .constant(false), buttonText: "버어튼") {
        print("Tapped FullWidthButton")
    }
}
