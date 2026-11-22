import SwiftUI

struct FilterChip: View {
    let title: String
    let count: Int
    let color: Color?
    /// The project this chip shows; `nil` is the chip for all projects.
    let project: String?
    @Binding var selection: String?

    private var isSelected: Bool { selection == project }

    var body: some View {
        Button(action: select) {
            HStack(spacing: Theme.chipSpacing) {
                if let color {
                    Circle()
                        .fill(color)
                        .frame(width: Theme.dotSize, height: Theme.dotSize)
                }
                Text(title)
                    .lineLimit(1)
                Text(count, format: .number)
                    .monospacedDigit()
                    .opacity(0.55)
            }
            .font(.callout)
            .padding(.horizontal, Theme.itemSpacing)
            .padding(.vertical, Theme.chipSpacing)
            .frame(maxWidth: Theme.chipMaxWidth)
            .foregroundStyle(isSelected ? AnyShapeStyle(.background) : AnyShapeStyle(.primary))
            .background(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.quaternary), in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel("\(title), \(openNotesLabel(count))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func select() {
        selection = project
    }
}
