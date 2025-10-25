import SwiftUI

struct SoundReactiveConfigView: View {
  @Bindable var show: SoundReactiveShow

  var body: some View {
    Form {
      Section("Theme") {
        Picker("Visual Theme", selection: $show.theme) {
          ForEach(SoundReactiveShow.Theme.allCases) { theme in
            Label {
              VStack(alignment: .leading, spacing: 4) {
                Text(theme.rawValue)
                  .font(.body)
                Text(theme.description)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            } icon: {
              Image(systemName: theme.icon)
            }
            .tag(theme)
          }
        }
        .pickerStyle(.inline)
        .labelsHidden()
      }

      Section("Audio Settings") {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Sensitivity")
            Spacer()
            Text(String(format: "%.0f%%", show.sensitivity * 100))
              .foregroundStyle(.secondary)
          }
          Slider(value: $show.sensitivity, in: 0.1...1.0)
          Text("How responsive lights are to quiet sounds")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Smoothing")
            Spacer()
            Text(String(format: "%.0f%%", show.smoothing * 100))
              .foregroundStyle(.secondary)
          }
          Slider(value: $show.smoothing, in: 0.0...0.95)
          Text("Lower = more reactive, higher = smoother transitions")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Section {
        Label {
          Text("Microphone access required")
        } icon: {
          Image(systemName: "mic.fill")
        }
        .foregroundStyle(.secondary)

        Text(
          "This light show uses your device's microphone to analyze sound and create reactive lighting effects. Grant microphone permission when prompted."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      Section {
        VStack(alignment: .leading, spacing: 8) {
          Text("Tips for best results:")
            .font(.subheadline)
            .fontWeight(.medium)

          VStack(alignment: .leading, spacing: 4) {
            Label("Play music or make sounds near your device", systemImage: "music.note")
            Label("Start with 50% sensitivity and adjust", systemImage: "slider.horizontal.3")
            Label("Try different themes for various music styles", systemImage: "sparkles")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  SoundReactiveConfigView(show: SoundReactiveShow())
}
