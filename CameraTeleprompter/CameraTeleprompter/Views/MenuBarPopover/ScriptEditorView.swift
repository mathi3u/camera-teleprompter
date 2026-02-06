import SwiftUI

struct ScriptEditorView: View {
    @Environment(TeleprompterState.self) private var state

    var body: some View {
        @Bindable var state = state

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Script")
                    .font(.headline)
                Spacer()
                Button {
                    if let clipboardString = NSPasteboard.general.string(forType: .string) {
                        state.currentScript.body = clipboardString
                        state.currentScript.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }
                .help("Paste from clipboard")
            }

            TextField("Title", text: $state.currentScript.title)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $state.currentScript.body)
                .font(.system(size: 13))
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
