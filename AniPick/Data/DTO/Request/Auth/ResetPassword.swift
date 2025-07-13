//
//  ResetPassword.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

struct ResetPasswordRequest: Encodable {
    let email: String
    let newPassword: String
    let checkNewPassword: String
}
