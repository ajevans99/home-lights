import SwiftUI

struct BassDropConfigView: View {
  @Bindable var show: BassDropShow

  var body: some View {
    Form {
      Section("Palette") {
        ColorPicker("Primary Glow", selection: $show.primaryColor)
        ColorPicker("Drop Accent", selection: $show.accentColor)
      }

      Section("Timing") {
        VStack(alignment: .leading, spacing: 12) {
          VStack(alignment: .leading) {
            Text("Drop Interval")
            Slider(value: $show.dropInterval, in: 3...12, step: 0.5)
            Text("Big hit every \(show.dropInterval, specifier: "%.1f") seconds")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading) {
            Text("Build-up Length")
            Slider(value: $show.buildUpDuration, in: 1...6, step: 0.25)
            Text("Rises over \(show.buildUpDuration, specifier: "%.2f") seconds")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading) {
            Text("Flash Duration")
            Slider(value: $show.flashDuration, in: 0.2...1.5, step: 0.1)
            Text("Drop lingers for \(show.flashDuration, specifier: "%.1f") seconds")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section("Texture") {
        VStack(alignment: .leading) {
          Text("Shimmer Amount")
          Slider(value: $show.shimmerAmount, in: 0...0.8, step: 0.05)
          Text(shimmerDescription)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Section {
        Text(
          "Simulates a DJ set with looping build-ups, shimmering anticipation, and explosive drops on cue."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }

  private var shimmerDescription: String {
    switch show.shimmerAmount {
    case ..<0.1: return "Smooth build"
    case ..<0.3: return "Mild vibration"
    case ..<0.6: return "Energetic shimmer"
    default: return "Relentless buzz"
    }
  }
}

#Preview {
  BassDropConfigView(show: BassDropShow())
}
