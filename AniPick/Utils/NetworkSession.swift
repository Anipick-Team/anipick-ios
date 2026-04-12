//
//  NetworkSession.swift
//  AniPick
//
//  인증이 필요한 API 호출에 사용하는 공유 Alamofire Session.
//  ViewModel마다 Session을 개별 생성하지 않고 이 공유 인스턴스를 사용합니다.
//

import Alamofire

enum NetworkSession {
    static let authenticated = Session(interceptor: TokenInterceptor.shared)
}
