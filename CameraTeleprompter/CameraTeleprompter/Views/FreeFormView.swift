import SwiftUI

/// No-script mode: shows CoachingHUD centered in window
struct FreeFormView: View {
    @Environment(CoachingState.self) private var coachingState

    var body: some View {
        VStack {
            Spacer()
            CoachingHUD()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
