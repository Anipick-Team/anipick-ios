import SwiftUI

struct CommunityToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.82))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
            .padding(.horizontal, 24)
    }
}
