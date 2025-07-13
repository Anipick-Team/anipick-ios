//
//  VerifyVaildNumber.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

struct VerifyVerificationCodeRequest: Encodable {
    let email: String
    let code: String
}
