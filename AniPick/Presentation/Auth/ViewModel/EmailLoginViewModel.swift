//
//  EmailLoginViewModel.swift
//  AniPick
//
//  Created by cho on 4/27/25.
//

import SwiftUI

class EmailLoginViewModel: ObservableObject {
    
    @Published var emailString: String = "" {
        didSet {
            print(emailString)
            validateInputs()
        }
    }
    @Published var passwordString: String = "" {
        didSet {
            print(passwordString)
            validateInputs()
        }
    }
    
    @Published var isEnableLoginButton: Bool = false
    
    func validateInputs()  {
        print("validateInputs 호출호출!")
        self.isEnableLoginButton = !emailString.isEmpty && !passwordString.isEmpty
    }
    
}
