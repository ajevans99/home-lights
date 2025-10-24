import SwiftUI

struct OceanWavesConfigView: View {
  @Bindable var show: OceanWavesShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Speed: \(String(format: "%.1f", show.speed))s")
          .font(.subheadline)

        Slider(value: $show.speed, in: 0.5...5.0, step: 0.1)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Wave Intensity: \(Int(show.waveIntensity * 100))%")
          .font(.subheadline)

        Slider(value: $show.waveIntensity, in: 0.3...1.0, step: 0.1)
      }

      Text("Lights undulate like ocean waves in blue and teal colors")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}
