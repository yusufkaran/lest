import SwiftUI

struct PanelHeader: View {
    let model: AppModel
    let loginItem: LoginItem
    @Binding var showsDone: Bool

    private var summary: String {
        model.openCount == 0 ? "No open notes" : openNotesLabel(model.openCount)
    }

    var body: some View {
        HStack(spacing: Theme.itemSpacing) {
            BrandTile()
            VStack(alignment: .leading, spacing: 0) {
                Text("Lest")
                    .font(.title3)
                    .bold()
                Text(summary)
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            OptionsMenu(model: model, loginItem: loginItem, showsDone: $showsDone)
        }
    }
}
