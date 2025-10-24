import SwiftUI

struct LightShowCard: View {
  let show: any LightShow
  let isSelected: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 12) {
        Image(systemName: show.icon)
          .font(.title2)
          .foregroundColor(isSelected ? .white : .accentColor)
          .frame(width: 40, height: 40)
          .background(
            isSelected
              ? Color.accentColor
              : Color.accentColor.opacity(0.1)
          )
          .cornerRadius(8)

        VStack(alignment: .leading, spacing: 4) {
          Text(show.name)
            .font(.headline)
            .foregroundColor(.primary)

          Text(show.description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.accentColor)
        }
      }
      .padding()
      .background(
        isSelected
          ? Color.accentColor.opacity(0.1)
          : Color.clear
      )
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            isSelected ? Color.accentColor : Color.clear,
            lineWidth: 2
          )
      )
    }
    .buttonStyle(.plain)
  }
}
