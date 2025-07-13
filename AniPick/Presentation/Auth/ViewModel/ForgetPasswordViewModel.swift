//
//  ForgetPasswordViewModel.swift
//  AniPick
//
//  Created by cho on 4/27/25.
//

import SwiftUI

class ForgetPasswordViewModel: ObservableObject {
    @Published var emailString: String = "" {
        didSet {
            
        }
    }
    
    @Published var verificationCode: String = "" {
        didSet {
            
        }
    }
    
    @Published var activeLoginButton: Bool = false
    
    func isVerificationCodeValid() {
        self.activeLoginButton = verificationCode.isEmpty == false && Int(verificationCode) != nil
    }
    
    
    
    
}
