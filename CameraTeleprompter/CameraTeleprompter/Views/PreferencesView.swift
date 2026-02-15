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
            Section("Coaching") {
                Toggle("Enable Coaching", isOn: $state.isCoachingEnabled)

                if state.isCoachingEnabled {
                    Picker("Mode", selection: $state.speechMode) {
                        Text("Script").tag(SpeechMode.teleprompter)
                        Text("Free").tag(SpeechMode.freeForm)
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section("Face Light") {
                Toggle("Enable Face Light", isOn: $state.isFaceLightEnabled)

                if state.isFaceLightEnabled {
                    HStack {
                        Text("Brightness")
                        Slider(value: $state.faceLightBrightness, in: 0.3...1.0, step: 0.05)
                        Text("\(Int(state.faceLightBrightness * 100))%")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 420)
    }
}
