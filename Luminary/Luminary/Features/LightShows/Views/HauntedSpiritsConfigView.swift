import SwiftUI

struct HauntedSpiritsConfigView: View {
  @Bindable var show: HauntedSpiritsShow

  var body: some View {
    Form {
      Section("Palette") {
        ColorPicker("Base Glow", selection: $show.baseColor)
        ColorPicker("Accent Flame", selection: $show.accentColor)
      }

      Section("Effects") {
        VStack(alignment: .leading, spacing: 12) {
          VStack(alignment: .leading) {
            Text("Flicker Intensity")
            Slider(value: $show.flickerIntensity, in: 0...1)
            Text(flickerDescription)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading) {
            Text("Pulse Interval")
            Slider(value: $show.pulseInterval, in: 1...10, step: 0.5)
            Text("Swap every \(show.pulseInterval, specifier: "%.1f") seconds")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading) {
            Text("Strobe Chance")
            Slider(value: $show.strobeChance, in: 0...0.5, step: 0.05)
            Text(strobeDescription)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section {
        Text(
          "Creates a haunted ambiance with drifting purples, embers of orange, and occasional candlelight flashes."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }

  private var flickerDescription: String {
    switch show.flickerIntensity {
    case ..<0.2: return "Steady glow"
    case ..<0.5: return "Gentle flicker"
    case ..<0.8: return "Lively flames"
    default: return "Chaotic spirits"
    }
  }

  private var strobeDescription: String {
    if show.strobeChance < 0.05 {
      return "Rare flashes"
    } else if show.strobeChance < 0.2 {
      return "Occasional flashes"
    } else {
      return "Frequent strobes"
    }
  }
}

#Preview {
  HauntedSpiritsConfigView(show: HauntedSpiritsShow())
}
