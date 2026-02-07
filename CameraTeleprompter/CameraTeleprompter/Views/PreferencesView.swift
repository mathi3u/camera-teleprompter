import SwiftUI

struct PreferencesView: View {
    @Environment(TeleprompterState.self) private var state

    var body: some View {
        @Bindable var state = state

        Form {
            Section("Text") {
                HStack {
                    Text("Font Size")
                    Slider(value: $state.fontSize, in: 14...48, step: 2)
                    Text("\(Int(state.fontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }

                HStack {
                    Text("Scroll Speed")
                    Slider(value: $state.scrollSpeed, in: 10...200, step: 5)
                    Text("\(Int(state.scrollSpeed)) pt/s")
                        .monospacedDigit()
                        .frame(width: 55, alignment: .trailing)
                }
            }

            Section("Window") {
                HStack {
                    Text("Opacity")
                    Slider(value: $state.windowOpacity, in: 0.3...1.0, step: 0.05)
                    Text("\(Int(state.windowOpacity * 100))%")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 240)
    }
}
