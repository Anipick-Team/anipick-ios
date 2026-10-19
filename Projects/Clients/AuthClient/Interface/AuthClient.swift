/// 로그인·로그아웃. 지금은 로그아웃만 있다 (Auth Feature 이관 때 늘린다).
public protocol AuthClient: Sendable {
    /// 서버에 로그아웃을 알리고, 결과와 무관하게 이 기기의 로그인 정보를 지운다.
    func logout() async
}
