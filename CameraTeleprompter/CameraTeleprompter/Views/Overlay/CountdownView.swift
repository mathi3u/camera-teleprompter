import SwiftUI

struct CountdownView: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: count)
    }
}
