import HomeLights
import SwiftUI

struct AvailableLightsSection: View {
  let lights: [DiscoveredDevices.Accessory]
  let onAdd: (DiscoveredDevices.Accessory) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Available Lights")
        .font(.headline)
        .padding(.horizontal)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(lights, id: \.name) { light in
            Button(action: { onAdd(light) }) {
              VStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                  .font(.title2)
                  .foregroundColor(.yellow)

                Text(light.name)
                  .font(.caption)
                  .lineLimit(2)
                  .multilineTextAlignment(.center)
              }
              .frame(width: 80, height: 80)
              .background(Color.secondary.opacity(0.1))
              .cornerRadius(12)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
      }
      .frame(height: 100)
    }
    .padding(.vertical)
  }
}
