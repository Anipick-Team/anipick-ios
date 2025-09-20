//
//  PersonDetailView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct PersonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: PersonDetailViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "캐릭터/성우진") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(viewModel.castList, id: \.self) { item in
                        // TODO: API 에서 데이터 가져와서 보여줘야함
                        Button {
                            self.viewModel.moveToVoiceActorView(personId: item.voiceActor?.id ?? 0)
                        } label: {
                            CharacterAndVoiceActorCellView(
                                characterImageUrl: item.character?.imageUrl ?? "",
                                charactreName: item.character?.name ?? "",
                                voiceActorImageUrl: item.voiceActor?.imageUrl ?? "",
                                voiceActorName: item.voiceActor?.name ?? ""
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden()
        .background(Color.white)
    }
    
    @ViewBuilder
    private func sectionDivder() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
        
    }
}
