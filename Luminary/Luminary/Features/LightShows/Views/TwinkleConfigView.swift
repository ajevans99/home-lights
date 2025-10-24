import SwiftUI

struct TwinkleConfigView: View {
  @Bindable var show: TwinkleShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Colors")
        .font(.headline)

      ColorPicker("Base Color", selection: $show.baseColor)
      ColorPicker("Twinkle Color", selection: $show.twinkleColor)

      VStack(alignment: .leading, spacing: 8) {
        Text("Frequency: \(Int(show.frequency * 100))%")
          .font(.subheadline)

        Slider(value: $show.frequency, in: 0.1...0.8, step: 0.1)
      }

      Text("Lights randomly sparkle at the selected frequency")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}
