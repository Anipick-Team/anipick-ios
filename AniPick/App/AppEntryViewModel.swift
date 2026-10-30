//
//  AppEntryViewModel.swift
//  AniPick
//
//  Created by cho on 7/19/25.
//

import MetadataClientInterface
import MetadataClientLive
import Networking
import SwiftUI
import Utils

/// 앱 시작 때 한 번 하는 요청. 레거시 Alamofire 요청을 HTTPClient로 옮겼다 (Phase 5)
@MainActor
final class AppEntryViewModel: ObservableObject {
    private let client: HTTPClient
    private let metadataClient: any MetadataClient
    private let retryDelay: Duration

    init(
        client: HTTPClient = AppSession.httpClient,
        metadataClient: (any MetadataClient)? = nil,
        retryDelay: Duration = .seconds(3)
    ) {
        self.client = client
        self.metadataClient = metadataClient ?? LiveMetadataClient(client: client)
        self.retryDelay = retryDelay
    }

    /// 결과는 로그로만 남긴다 (레거시와 같음)
    func checkVersion() async {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let endpoint = Endpoint<EmptyResult>(
            method: .get,
            path: "api/version",
            query: [
                URLQueryItem(name: "userAppVersion", value: appVersion),
                URLQueryItem(name: "platform", value: "IOS"),
            ],
            requiresAuth: true
        )
        do {
            let data = try await client.sendRaw(endpoint)
            DLog("version check success - \(String(decoding: data, as: UTF8.self))")
        } catch {
            DLog("version check에서 error 발생 - \(error)")
        }
    }

    /// 실패하면 `retryDelay` 뒤 최대 `retryCount`번 다시 받는다 (레거시 3초·3번)
    func fetchMetaData(retryCount: Int = 3) async {
        for attempt in 0...retryCount {
            if await metadataClient.refresh() {
                return
            }
            DLog("meta data fetch 실패 - 시도 \(attempt + 1)")
            guard attempt < retryCount else {
                return
            }
            try? await Task.sleep(for: retryDelay)
        }
    }
}
