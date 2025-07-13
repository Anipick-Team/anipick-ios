//
//  EmailSignupRequest.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

struct EmailSignupRequest: Codable {
    let email: String
    let password: String
    let termsAndConditions: Bool
}
