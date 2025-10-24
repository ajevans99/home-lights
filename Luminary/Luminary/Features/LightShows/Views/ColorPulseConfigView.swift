import SwiftUI

struct ColorPulseConfigView: View {
  @Bindable var show: ColorPulseShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Pulse Color")
        .font(.headline)

      ColorPicker("Color", selection: $show.pulseColor)
        .labelsHidden()
        .frame(height: 150)

      VStack(alignment: .leading, spacing: 8) {
        Text("Speed: \(String(format: "%.1f", show.speed))s per pulse")
          .font(.subheadline)

        Slider(value: $show.speed, in: 0.2...5.0, step: 0.1)
      }

      Text("All lights pulse together in sync")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}
