import SwiftUI

struct SettingsView: View {
    @Environment(TeleprompterState.self) private var state

    var body: some View {
        @Bindable var state = state

        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            // Font size
            HStack {
                Text("Font Size")
                Spacer()
                Slider(value: $state.fontSize, in: 14...48, step: 2) {
                    Text("Font Size")
                }
                .frame(width: 120)
                Text("\(Int(state.fontSize))")
                    .monospacedDigit()
                    .frame(width: 30)
            }

            // Scroll speed
            HStack {
                Text("Scroll Speed")
                Spacer()
                Slider(value: $state.scrollSpeed, in: 10...200, step: 5) {
                    Text("Speed")
                }
                .frame(width: 120)
                Text("\(Int(state.scrollSpeed))")
                    .monospacedDigit()
                    .frame(width: 30)
            }

            // Display mode
            Picker("Display", selection: $state.displayMode) {
                ForEach(DisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Divider()

            // Voice control
            Toggle("Voice Control", isOn: $state.isVoiceControlEnabled)

            if state.isVoiceControlEnabled {
                HStack {
                    Text("Voice Threshold")
                    Spacer()
                    Slider(value: $state.voiceThreshold, in: -50...(-10), step: 1) {
                        Text("Threshold")
                    }
                    .frame(width: 120)
                    Text("\(Int(state.voiceThreshold)) dB")
                        .monospacedDigit()
                        .frame(width: 50)
                }
            }

            // Text color
            ColorPicker("Text Color", selection: $state.textColor)
        }
    }
}
