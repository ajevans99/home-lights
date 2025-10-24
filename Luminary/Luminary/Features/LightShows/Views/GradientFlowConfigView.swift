import SwiftUI

struct GradientFlowConfigView: View {
  @Bindable var show: GradientFlowShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Gradient Colors")
        .font(.headline)

      ColorPicker("Start Color", selection: $show.startColor)
      ColorPicker("End Color", selection: $show.endColor)

      VStack(alignment: .leading, spacing: 8) {
        Text("Speed: \(String(format: "%.1f", show.speed))s")
          .font(.subheadline)

        Slider(value: $show.speed, in: 0.5...5.0, step: 0.1)
      }

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Direction")
            .font(.subheadline)

          Spacer()

          Image(systemName: show.direction.icon)
            .foregroundColor(.secondary)
        }

        Picker("Direction", selection: $show.direction) {
          ForEach(GradientFlowShow.GradientDirection.allCases) { dir in
            Label(dir.rawValue, systemImage: dir.icon).tag(dir)
          }
        }
        .pickerStyle(.segmented)
      }

      Text("Gradient flows smoothly across lights based on position")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}
