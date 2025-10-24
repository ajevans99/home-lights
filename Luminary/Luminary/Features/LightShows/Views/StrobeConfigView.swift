import SwiftUI

struct StrobeConfigView: View {
  @Bindable var show: StrobeShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Strobe Color")
        .font(.headline)

      ColorPicker("Color", selection: $show.strobeColor)
        .labelsHidden()
        .frame(height: 150)

      VStack(alignment: .leading, spacing: 8) {
        Text("Speed: \(String(format: "%.2f", show.speed))s")
          .font(.subheadline)

        Slider(value: $show.speed, in: 0.05...1.0, step: 0.05)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Intensity: \(Int(show.intensity))%")
          .font(.subheadline)

        Slider(value: $show.intensity, in: 10...100, step: 5)
      }

      Text("⚠️ Warning: Strobe effects may trigger seizures in photosensitive individuals")
        .font(.caption)
        .foregroundColor(.orange)
    }
    .padding()
  }
}
