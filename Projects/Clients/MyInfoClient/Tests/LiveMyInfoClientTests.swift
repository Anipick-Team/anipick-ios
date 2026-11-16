import ClientCore
import Foundation
import MyInfoClientInterface
import Networking
import Storage
import Testing

@testable import MyInfoClientLive

@Suite("LiveMyInfoClient", .timeLimit(.minutes(1)))
struct LiveMyInfoClientTests {
    static let imageBase = URL(string: "https://anipick.example/")!

    private func query(_ request: URLRequest) -> [String: String] {
        let items =
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    @Test(
        "L1. 볼·보는 중·다 본 애니: 상태별 경로에 status·lastId·size=20을 보낸다",
        arguments: [
            (WatchStatus.watchList, "/api/mypage/animes/watchlist"),
            (.watching, "/api/mypage/animes/watching"), (.finished, "/api/mypage/animes/finished"),
        ]
    )
    func watchList(status: WatchStatus, path: String) async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":42,"cursor":{"lastId":9},"animes":[{"animeId":1,"userAnimeStatusId":3,"title":"A","coverImageUrl":"u","myRating":4.5}]}}"#
            ))

        let page = try await LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)
            .watchList(status, lastId: 7)

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path() == path)
        #expect(query(request) == ["status": status.rawValue, "lastId": "7", "size": "20"])
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(
            page
                == MyPage(
                    count: 42,
                    items: [MyAnime(animeId: 1, title: "A", coverImageUrl: "u", myRating: 4.5)],
                    lastId: 9))
    }

    @Test("L1. 첫 페이지는 lastId를 보내지 않는다. animes가 없으면 빈 목록")
    func watchListFirstPage() async throws {
        let stub = ClientStub(
            .json(#"{"code":200,"value":"SUCCESS","result":{"count":0,"cursor":{"lastId":0}}}"#))

        let page = try await LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)
            .watchList(.watching, lastId: nil)

        #expect(query(try #require(stub.requests.first)) == ["status": "WATCHING", "size": "20"])
        #expect(page == MyPage(count: 0, items: [], lastId: 0))
    }

    @Test("L4. 좋아요한 작품: api/mypage/animes/like, size=20, 커서가 없어도 된다")
    func likedAnimes() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":3,"cursor":null,"animes":[{"animeId":5,"animeLikeId":1,"title":"B","coverImageUrl":null}]}}"#
            ))

        let page = try await LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)
            .likedAnimes(lastId: nil)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/mypage/animes/like")
        #expect(query(request) == ["size": "20"])
        #expect(
            page
                == MyPage(
                    count: 3, items: [MyAnime(animeId: 5, title: "B", coverImageUrl: nil)],
                    lastId: nil))
    }

    @Test("L5. 좋아요한 인물: api/mypage/persons/like, size=30")
    func likedPersons() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":1,"cursor":{"lastId":4},"persons":[{"personId":8,"userLikedVoiceActorId":2,"name":"성우","profileImageUrl":"p"}]}}"#
            ))

        let page = try await LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)
            .likedPersons(lastId: 2)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/mypage/persons/like")
        #expect(query(request) == ["lastId": "2", "size": "30"])
        #expect(
            page
                == MyPage(
                    count: 1, items: [MyPerson(personId: 8, name: "성우", profileImageUrl: "p")],
                    lastId: 4))
    }

    @Test("결과가 없는 응답은 실패 (레거시도 디코딩 실패로 아무것도 하지 않는다)")
    func missingResultFails() async {
        let stub = ClientStub(.json(#"{"code":500,"value":"FAIL","result":null}"#))

        await #expect(throws: TransportError.decoding) {
            _ = try await LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)
                .likedPersons(lastId: nil)
        }
    }

    @Test("RA1. 평가한 작품: api/mypage/animes/rated에 정렬·커서·size=20·reviewOnly=false")
    func ratedReviews() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":12,"cursor":{"sort":"likes","lastId":31},"reviews":[{"animeId":1,"title":"A","coverImageUrl":null,"rating":4.5,"reviewId":31,"reviewContent":"좋다","createdAt":"2026.10.01","likeCount":2,"isLiked":false}]}}"#
            ))
        let client = LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)

        let page = try await client.ratedReviews(
            sort: .likes, lastId: 30, lastLikeCount: 5, lastRating: 4.0)
        _ = try await client.ratedReviews(
            sort: .latest, lastId: nil, lastLikeCount: nil, lastRating: nil)

        #expect(stub.requests.first?.url?.path() == "/api/mypage/animes/rated")
        #expect(
            query(stub.requests[0])
                == [
                    "lastId": "30", "lastLikeCount": "5", "lastRating": "4.0", "size": "20",
                    "sort": "likes", "reviewOnly": "false",
                ])
        #expect(query(stub.requests[1]) == ["size": "20", "sort": "latest", "reviewOnly": "false"])
        #expect(
            page
                == RatedPage(
                    count: 12, lastId: 31,
                    reviews: [
                        RatedReview(
                            animeId: 1, title: "A", coverImageUrl: nil, rating: 4.5, reviewId: 31,
                            reviewContent: "좋다", createdAt: "2026.10.01", likeCount: 2)
                    ]))
    }

    @Test(
        "MC1. 내 게시글: api/mypage/community/posts, size=20. 첨부 이미지 id는 {서버}api/image/{id}로, 장르는 첫 번째 이름"
    )
    func myPosts() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":3,"cursor":{"lastId":40},"posts":[{"postId":40,"seriesId":1,"animeTitle":"A","animeCoverImageUrl":"c","genres":[{"id":1,"name":"액션"},{"id":2,"name":"SF"}],"title":"제목","content":"본문","thumbnailImageId":9,"isSpoiler":true,"viewCount":5,"likeCount":2,"commentCount":1,"createdAt":"2026.10.29"}]}}"#
            ))

        let page = try await LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)
            .myPosts(lastId: 41)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/mypage/community/posts")
        #expect(query(request) == ["lastId": "41", "size": "20"])
        #expect(page.count == 3)
        #expect(page.lastId == 40)
        #expect(
            page.items.first?.thumbnailURL?.absoluteString == "https://anipick.example/api/image/9")
        #expect(page.items.first?.genre == "액션")
    }

    @Test("MC1. 내 댓글: api/mypage/community/comments, 결과 값은 모두 비어 있어도 된다")
    func myComments() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":null,"cursor":null,"comments":[{"commentId":7}]}}"#
            ))

        let page = try await LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)
            .myComments(lastId: nil)

        #expect(stub.requests.first?.url?.path() == "/api/mypage/community/comments")
        #expect(query(try #require(stub.requests.first)) == ["size": "20"])
        #expect(
            page
                == ContentPage(
                    count: nil, lastId: nil,
                    items: [
                        MyComment(
                            commentId: 7, postId: nil, animeTitle: nil, animeCoverImageUrl: nil,
                            genre: nil, postTitle: nil, content: nil, likeCount: nil, createdAt: nil
                        )
                    ]))
    }

    @Test("MM1. 마이페이지: GET api/mypage, 개수·좋아요한 작품·프로필 주소")
    func profile() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"nickname":"n","profileImageUrl":"https://x/api/image/12","watchCounts":{"watchList":1,"watching":2,"finished":3},"likedAnimes":[{"animeId":5,"animeLikeId":1,"title":"B","coverImageUrl":null}],"likedPersons":[]}}"#
            ))

        let profile = try await LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)
            .profile()

        #expect(stub.requests.first?.url?.path() == "/api/mypage")
        #expect(
            profile
                == MyProfile(
                    profileImageUrl: "https://x/api/image/12",
                    watchCounts: .init(watchList: 1, watching: 2, finished: 3),
                    likedAnimes: [MyAnime(animeId: 5, title: "B", coverImageUrl: nil)]))
    }

    @Test("MM2. 프로필 이미지: GET api/image/{id}, 토큰, 본문 그대로")
    func profileImage() async throws {
        let stub = ClientStub(.json("IMAGEBYTES"))

        let data = try await LiveMyInfoClient(client: stub.client, imageBaseURL: Self.imageBase)
            .profileImage(id: 12)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/image/12")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(String(decoding: data, as: UTF8.self) == "IMAGEBYTES")
    }

    @Test(
        "MM5. 업로드: POST api/image/profile-image(HTTPS 기본 주소) multipart profileImageFile, 받은 id를 imageId에 저장"
    )
    func upload() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":{"imageId":77}}"#))
        let defaults = UserDefaults(suiteName: "myinfo-\(UUID().uuidString)")!
        let client = LiveMyInfoClient(
            client: stub.client, imageBaseURL: Self.imageBase,
            preferences: Preferences(defaults: defaults))

        let id = try await client.uploadProfileImage(jpeg: Data([1, 2, 3]))

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.scheme == "https")
        #expect(request.url?.path() == "/api/image/profile-image")
        #expect(
            request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data")
                == true)
        #expect(id == 77)
        #expect(defaults.integer(forKey: "imageId") == 77)
        let body = String(
            decoding: LiveMyInfoClient.uploadEndpoint(jpeg: Data([1])).multipartBody, as: UTF8.self)
        #expect(body.contains(#"name="profileImageFile"; filename="profile.jpg""#))
        #expect(body.contains("Content-Type: image/jpeg"))
    }
}

extension Endpoint {
    fileprivate var multipartBody: Data {
        guard case .multipart(let form) = body else {
            return Data()
        }
        return form.encoded()
    }
}
