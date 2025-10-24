import SwiftUI

struct WaveColorConfigView: View {
  @Bindable var show: WaveColorShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Wave Color")
        .font(.headline)

      ColorPicker("Wave Color", selection: $show.waveColor)

      ColorPicker("Rest Color", selection: $show.restColor)

      VStack(alignment: .leading, spacing: 8) {
        Text("Duration per Light: \(String(format: "%.1f", show.durationPerLight))s")
          .font(.subheadline)

        Slider(value: $show.durationPerLight, in: 0.1...5.0, step: 0.1)
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

      Text("Lights will wave in the selected order, one at a time")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}
