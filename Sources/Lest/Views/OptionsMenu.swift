import SwiftUI

struct OptionsMenu: View {
    let model: AppModel
    @Bindable var loginItem: LoginItem
    @Binding var showsDone: Bool

    var body: some View {
        Menu {
            Toggle("Show Completed", isOn: $showsDone)
            Button("Clear Completed", action: model.clearDone)
                .disabled(model.doneCount == 0)
            Divider()
            Toggle("Open at Login", isOn: $loginItem.isEnabled)
            Divider()
            Button("Quit Lest", action: quit)
                .keyboardShortcut("q")
        } label: {
            PhosphorIcon(.dotsThreeBold, size: Theme.menuBarIconSize)
                .frame(width: Theme.controlSize, height: Theme.controlSize)
                .contentShape(.rect)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .background(.quaternary, in: .rect(cornerRadius: Theme.controlRadius))
        .fixedSize()
        .accessibilityLabel("Options")
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
