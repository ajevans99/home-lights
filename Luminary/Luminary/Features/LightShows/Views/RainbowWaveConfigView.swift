import SwiftUI

struct RainbowWaveConfigView: View {
  @Bindable var show: RainbowWaveShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Speed: \(String(format: "%.1f", show.speed))s per light")
          .font(.subheadline)

        Slider(value: $show.speed, in: 0.1...3.0, step: 0.1)
      }

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Order")
            .font(.subheadline)

          Spacer()

          Image(systemName: show.orderingStrategy.icon)
            .foregroundColor(.secondary)
        }

        Picker("Order", selection: $show.orderingStrategy) {
          ForEach(LightOrderingStrategy.allCases) { strategy in
            Label(strategy.rawValue, systemImage: strategy.icon).tag(strategy)
          }
        }
        .pickerStyle(.menu)

        Text(show.orderingStrategy.description)
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      Text("Lights will cycle through rainbow colors continuously")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}
