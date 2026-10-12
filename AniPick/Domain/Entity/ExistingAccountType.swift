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
        switch errorCode {
        case 133: self = .email
        case 134: self = .kakao
        case 135: self = .google
        case 136: self = .apple
        default: return nil
        }
    }

    private var name: String {
        switch self {
        case .email: return "이메일"
        case .kakao: return "카카오"
        case .google: return "구글"
        case .apple: return "애플"
        }
    }

    var title: String {
        return "\(name)로 가입된 계정입니다."
    }

    var message: String {
        return "\(name)로 로그인해주세요."
    }

    var confirmTitle: String {
        return "\(name)로 로그인"
    }
}
