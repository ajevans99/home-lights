import SwiftUI

struct NeonPartyConfigView: View {
  @Bindable var show: NeonPartyShow

  var body: some View {
    Form {
      Section("Palette") {
        Picker("Palette", selection: $show.palette) {
          ForEach(NeonPartyShow.Palette.allCases) { palette in
            Label(palette.rawValue, systemImage: palette.icon)
              .tag(palette)
          }
        }
        Text(show.palette.tagline)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("Effects") {
        VStack(alignment: .leading, spacing: 12) {
          VStack(alignment: .leading) {
            Text("Speed")
            Slider(value: $show.speed, in: 0.1...0.8)
            Text("Rotation speed: \(show.speed, specifier: "%.2f")")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading) {
            Text("Sparkle Chance")
            Slider(value: $show.sparkleChance, in: 0...0.6)
            Text(sparkleDescription)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading) {
            Text("Base Brightness")
            Slider(value: $show.baseBrightness, in: 40...90)
            Text("Minimum brightness \(Int(show.baseBrightness))")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section {
        Text(
          "Lights loop through neon hues with rolling waves and random sparkles for high-energy parties."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }

  private var sparkleDescription: String {
    switch show.sparkleChance {
    case ..<0.1: return "Occasional shimmer"
    case ..<0.3: return "Steady sparkles"
    case ..<0.5: return "Hyper sparkle"
    default: return "Strobe party"
    }
  }
}

#Preview {
  NeonPartyConfigView(show: NeonPartyShow())
}
