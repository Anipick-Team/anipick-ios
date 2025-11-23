//
//  MyReviewPopupView.swift
//  AniPick
//
//  Created by cho on 11/2/25.
//
import SwiftUI

struct MyReviewPopupView: View {
    
    @Binding var isShowBlockMenu: Bool
    let deleteAction: () -> Void
    let editAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isShowBlockMenu {
                VStack(spacing: 0) {
                    Button {
                        // TODO: 삭제 액션 필요
                        deleteAction()
                    } label: {
                        Text("삭제")
                            .font(.system(size: 14))
                            .foregroundStyle(.anipickBlack)
                            .padding(15)
                    }
                    
                    Rectangle()
                        .padding(.horizontal, 15)
                        .foregroundStyle(.gray5)
                        .frame(height: 1)
                    
                    Button {
                        // TODO: 수정 액션 넣어야함
                        editAction()
                    } label: {
                        Text("수정")
                            .font(.system(size: 14))
                            .foregroundStyle(.anipickBlack)
                            .padding(15)
                    }
                }
                .frame(width: 72)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .border(.gray5)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .cornerRadius(8)
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .zIndex(1)
            }
        }
    }
}
