//
//  DeepLinkTarget.swift
//  AniPick
//
//  딥링크가 여는 화면 (Phase 4-1). 상태를 바꾸지 않는 순수 함수로 두어 테스트에서 바로 확인한다.
//

import DetailInterface
import ExploreInterface
import SwiftUI

/// 딥링크가 여는 Feature 화면. 탭은 바꾸지 않고 지금 탭의 스택을 이 화면 하나로 바꾼다 (레거시와 같음)
enum DeepLinkTarget: Equatable {
    case detail(DetailRoute)
    case explore(ExploreRoute)

    /// 제작사는 레거시처럼 이동하지 않는다 (DetailRoute.producer는 있지만 동작을 바꾸지 않음)
    static func target(for link: DeepLink) -> DeepLinkTarget? {
        switch link {
        case .anime(let id):
            return .detail(.anime(id: id))
        case .communityPost(let id):
            return .explore(.communityPost(id: id))
        case .producer, .unknown:
            return nil
        }
    }

    /// 스택을 이 화면 하나로
    var path: NavigationPath {
        var path = NavigationPath()
        switch self {
        case .detail(let route):
            path.append(route)
        case .explore(let route):
            path.append(route)
        }
        return path
    }
}
