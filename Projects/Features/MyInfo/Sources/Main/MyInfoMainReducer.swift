import DetailInterface
import Foundation
import MVICore
import MyInfoClientInterface
import MyInfoInterface
import Navigation
import SettingInterface
import UIKit

/// 마이페이지 메인(하단 "마이" 탭). 동작 목록: notes/2026-10-29-R-myinfo-04-main.md (MM1~MM12)
struct MyInfoMainReducer: Reducer {
    static let feedbackURL = URL(
        string:
            "https://docs.google.com/forms/d/e/1FAIpQLSdV4UANNQuVanRQ99JLJ1PU9ElXMN2iKx9gPaBXAb0QkVreDg/viewform"
    )!

    let myInfoClient: any MyInfoClient
    let navigator: any Navigator
    let openURL: @MainActor @Sendable (URL) -> Void

    struct State: Equatable {
        var watchListCount = 0
        var watchingCount = 0
        var finishedCount = 0
        var likedAnimes: [MyAnime] = []
        var likedPersons: [MyPerson] = []
        /// 이미지로 읽히는 바이트만 둔다. 없으면 기본 구름 이미지 (MM2)
        var profileImage: Data?
        var isImagePickerPresented = false
    }

    enum Intent: Sendable {
        case appeared
        case profileLoaded(MyProfile)
        case profileImageLoaded(Data)
        case likedPersonsLoaded(MyPage<MyPerson>)
        case settingTapped
        case feedbackTapped
        case routeTapped(MyInfoRoute)
        case animeTapped(MyAnime)
        case personTapped(MyPerson)
        case editProfileTapped
        case imagePickerPresentedChanged(Bool)
        case imagePicked(Data)
        case uploadFinished
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 정보와 좋아요한 인물을 다시 받는다 (MM1·MM4)
            return .merge([fetchProfile(), fetchLikedPersons()])

        case .profileLoaded(let profile):
            // 개수가 없으면 좋아요한 작품·프로필 이미지도 건너뛴다 (레거시 그대로)
            guard let counts = profile.watchCounts else {
                return .none
            }
            state.watchingCount = counts.watching ?? 0
            state.watchListCount = counts.watchList ?? 0
            state.finishedCount = counts.finished ?? 0
            state.likedAnimes = profile.likedAnimes ?? []
            let imageId = Self.imageId(from: profile.profileImageUrl)
            return .run { [myInfoClient] in
                guard let data = try? await myInfoClient.profileImage(id: imageId) else {
                    return nil
                }
                return .profileImageLoaded(data)
            }

        case .profileImageLoaded(let data):
            state.profileImage = UIImage(data: data) == nil ? nil : data
            return .none

        case .likedPersonsLoaded(let page):
            // 첫 30명으로 바꾼다 (MM4)
            state.likedPersons = page.items
            return .none

        case .settingTapped:
            return push(SettingRoute.main)

        case .feedbackTapped:
            return .run { [openURL] in
                await openURL(Self.feedbackURL)
                return nil
            }

        case .routeTapped(let route):
            return push(route)

        case .animeTapped(let anime):
            return push(DetailRoute.anime(id: anime.animeId ?? 0))

        case .personTapped(let person):
            return push(DetailRoute.voiceActor(id: person.personId ?? 0))

        case .editProfileTapped:
            state.isImagePickerPresented.toggle()
            return .none

        case .imagePickerPresentedChanged(let isPresented):
            let wasPresented = state.isImagePickerPresented
            state.isImagePickerPresented = isPresented
            // 사진 선택 창이 닫히면 정보를 다시 받는다 (MM8)
            return wasPresented && !isPresented ? fetchProfile() : .none

        case .imagePicked(let jpeg):
            // 올리는 동안 선택 창은 열린 채로 둔다. 결과와 무관하게 끝나면 닫는다 (MM7)
            return .run { [myInfoClient] in
                _ = try? await myInfoClient.uploadProfileImage(jpeg: jpeg)
                return .uploadFinished
            }

        case .uploadFinished:
            return reduce(into: &state, intent: .imagePickerPresentedChanged(false))
        }
    }

    /// 프로필 주소의 마지막 경로를 이미지 id로 쓴다. 없거나 숫자가 아니면 0 (레거시 `convertUrltoProfileId`)
    static func imageId(from url: String?) -> Int {
        guard let last = url?.components(separatedBy: "/").last else {
            return 0
        }
        return Int(last) ?? 0
    }

    private func fetchProfile() -> Effect<Intent> {
        return .run { [myInfoClient] in
            guard let profile = try? await myInfoClient.profile() else {
                return nil
            }
            return .profileLoaded(profile)
        }
    }

    private func fetchLikedPersons() -> Effect<Intent> {
        return .run { [myInfoClient] in
            guard let page = try? await myInfoClient.likedPersons(lastId: nil) else {
                return nil
            }
            return .likedPersonsLoaded(page)
        }
    }

    private func push(_ route: some Hashable & Sendable) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
