import ProjectDescription

/// Feature·Client 사이의 의존. **Interface 타깃만** 가리킬 수 있게 만들어
/// 구현 타깃 간 의존을 매니페스트 단계에서 막는다 (TMA 의존 규칙, tech-stack C7 ①).
/// Live 구현과 Feature 구현의 연결은 App만 한다.
public struct InterfaceDependency {
    let interface: TargetDependency
    /// Tests·Example에서 쓰는 가짜 구현(가짜 빌더, 시나리오형 Mock)
    let testing: TargetDependency

    public static func feature(_ name: String) -> InterfaceDependency {
        let path = ModuleLayer.features.path(name)
        return InterfaceDependency(
            interface: .project(target: "\(name)Interface", path: path),
            testing: .project(target: "\(name)Testing", path: path)
        )
    }

    public static func client(_ name: String) -> InterfaceDependency {
        let path = ModuleLayer.clients.path("\(name)Client")
        return InterfaceDependency(
            interface: .project(target: "\(name)ClientInterface", path: path),
            testing: .project(target: "\(name)ClientTesting", path: path)
        )
    }
}

/// Core·Shared 모듈과 외부 패키지 의존. Core·Shared는 상위 모듈(Feature·Client)을 알지 못한다.
public struct ModuleDependency {
    let target: TargetDependency
    /// 외부 SDK(정적 라이브러리)는 모듈 framework에 이미 링크되므로 테스트 타깃에 다시 넣지 않는다.
    var isExternal = false

    public static func core(_ name: String) -> ModuleDependency {
        return ModuleDependency(target: .project(target: name, path: ModuleLayer.core.path(name)))
    }

    public static func shared(_ name: String) -> ModuleDependency {
        return ModuleDependency(target: .project(target: name, path: ModuleLayer.shared.path(name)))
    }

    /// 외부 SDK는 소유 모듈 한 곳에서만 의존한다 (Firebase → Analytics, Kakao·Google → AuthClientLive).
    public static func external(_ name: String) -> ModuleDependency {
        return ModuleDependency(target: .external(name: name), isExternal: true)
    }
}

public enum ModuleLayer: String {
    case features = "Features"
    case clients = "Clients"
    case core = "Core"
    case shared = "Shared"

    func path(_ name: String) -> Path {
        return .relativeToRoot("Projects/\(rawValue)/\(name)")
    }
}
