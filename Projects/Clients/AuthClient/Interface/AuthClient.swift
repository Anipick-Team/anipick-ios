/// 로그인·로그아웃. 지금은 로그아웃만 있다 (Auth Feature 이관 때 늘린다).
public protocol AuthClient: Sendable {
    /// 서버 응답을 기다린 뒤, 결과와 무관하게 이 기기의 로그인 정보를 지운다 (이메일 변경 후).
    func logout() async
    /// 지우기 직전 토큰으로 서버에 알려 두고, 응답을 기다리지 않고 바로 지운다 (설정 → 로그아웃).
    func logoutImmediately() async
}
