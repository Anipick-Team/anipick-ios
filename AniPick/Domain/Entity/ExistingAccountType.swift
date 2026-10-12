//
//  ExistingAccountType.swift
//  AniPick
//

/// 소셜 로그인 시 같은 이메일로 이미 가입된 계정의 가입 수단 (서버 에러 코드 133~136)
enum ExistingAccountType: Equatable {
    case email
    case kakao
    case google
    case apple

    init?(errorCode: Int) {
        return nil
    }

    var title: String {
        return ""
    }

    var message: String {
        return ""
    }

    var confirmTitle: String {
        return ""
    }
}
