import SwiftUI

struct AlternatingColorsConfigView: View {
  @Bindable var show: AlternatingColorsShow

  var body: some View {
    Form {
      Section("Colors") {
        ColorPicker("Primary Color", selection: $show.primaryColor)
        ColorPicker("Secondary Color", selection: $show.secondaryColor)
      }

      Section("Timing") {
        VStack(alignment: .leading, spacing: 8) {
          Slider(value: $show.switchInterval, in: 0.5...10.0, step: 0.5)
          Text("Switch every \(show.switchInterval, specifier: "%.1f") seconds")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Section {
        Text(
          "Lights alternate between the two colors and swap which set is active after each interval."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  AlternatingColorsConfigView(show: AlternatingColorsShow())
}
