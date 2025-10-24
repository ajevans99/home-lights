import SwiftUI

struct FireEffectConfigView: View {
  @Bindable var show: FireEffectShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Intensity: \(Int(show.intensity * 100))%")
          .font(.subheadline)

        Slider(value: $show.intensity, in: 0.3...1.0, step: 0.1)
      }

      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Circle()
            .fill(Color(hue: 0 / 360, saturation: 1, brightness: 0.9))
            .frame(width: 20, height: 20)
          Text("Red")
            .font(.caption)
        }

        HStack {
          Circle()
            .fill(Color(hue: 30 / 360, saturation: 1, brightness: 0.9))
            .frame(width: 20, height: 20)
          Text("Orange")
            .font(.caption)
        }

        HStack {
          Circle()
            .fill(Color(hue: 50 / 360, saturation: 1, brightness: 0.9))
            .frame(width: 20, height: 20)
          Text("Yellow")
            .font(.caption)
        }
      }

      Text("Lights flicker randomly in warm fire colors")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}
