import ProjectDescription

public enum ProjectEnvironment {
    public static let teamID = "3K4KWAG7KD"
    public static let bundleIDPrefix = "com.moana"
    public static let destinations: Destinations = [.iPhone]
    public static let deploymentTargets: DeploymentTargets = .iOS("17.0")
}

/// 모듈 프레임워크의 링크 방식.
/// 개발 중에는 dynamic framework(빌드 속도·Preview 안정성), 릴리스 빌드는
/// `TUIST_PRODUCT_TYPE=static tuist generate`로 static framework를 생성한다 (TMA 권장, tech-stack C2).
public var moduleProduct: Product {
    let productType = Environment.productType.getString(default: "dynamic")
    return productType == "static" ? .staticFramework : .framework
}
