//
//  DataRollbackBannerView.swift
//  AniPick
//
//  홈 화면 상단 데이터 롤백 안내 배너
//

import SwiftUI

struct DataRollbackBannerView: View {
    /// "자세히 보기" 탭 시 상세 안내(팝업)를 여는 콜백
    var onDetailTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 폴더 아이콘 (원형 배경)
            Circle()
                .fill(Color.gray5)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "folder.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.anipickBlack)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("데이터 롤백 안내")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.anipickBlack)

                    Button(action: onDetailTap) {
                        Text("자세히 보기")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.anipickBlack))
                    }

                    Spacer(minLength: 0)
                }

                Text("서버 복구 과정에서 일부 데이터가 롤백되었음을 안내 드립니다.\n서비스 이용에 큰 불편을 드린 점 진심으로 사과드립니다.")
                    .font(.system(size: 13))
                    .foregroundColor(.anipickBlack)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray7)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}
