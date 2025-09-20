//
//  TextFieldComponents.swift
//  AniPick
//
//  Created by cho on 5/3/25.
//

import SwiftUI

struct TextFieldComponents: View {
    @State var titleText: String
    @State var placeholderText: String
    @Binding var textFieldString: String
    @State var enableEyeIcon: Bool = false
    @State var enableTimer: Bool = false
    @State var timerCount: String = "sdd"
    @State private var eyeIconVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titleText)
                .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)
            
            ZStack {
                if enableEyeIcon {
                    SecureField(
                        "",
                        text: $textFieldString,
                        prompt: Text(placeholderText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .autocapitalization(.none)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
                } else {
                    TextField(
                        "",
                        text: $textFieldString,
                        prompt: Text(placeholderText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .autocapitalization(.none)
                    .foregroundColor(.anipickBlack)
                    .padding(16)
                    .background(.textFieldBackground)
                    .cornerRadius(8)
                }
                
                if enableEyeIcon {
                    Button {
                        self.eyeIconVisible.toggle()
                    } label: {
                        HStack {
                            Spacer()
                            Image(self.eyeIconVisible ? .eyeVisibleIcons : .eyeUnvisibleIcons )
                                .padding(.trailing, 15)
                        }
                    }
                }
                
                if enableTimer {
                    HStack {
                        Spacer()
                        Text(timerCount)
                            .customFontStyle(size: 16, color: .point)
                            .padding(.trailing, 15)
                    }
                }
            }
        }
        
    }
}

#Preview {
    TextFieldComponents(
        titleText: "title",
        placeholderText: "placeholder",
        textFieldString: .constant("testString"),
        enableTimer: true,
        timerCount: "3:00"
    )
    .padding(20)
}
