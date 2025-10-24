import SwiftUI

struct LightShowControlPanel: View {
  @Binding var selectedShow: (any LightShow)?
  let lightPositions: [(name: String, position: CGPoint)]
  let onApply: () -> Void

  @State private var showSequenceExpanded = false

  @Environment(LightShowRegistry.self) private var registry

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      VStack(alignment: .leading, spacing: 8) {
        Text("Light Shows")
          .font(.title2)
          .fontWeight(.bold)

        Text("Select and configure light sequences")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding()

      Divider()

      // Show list
      ScrollView {
        VStack(spacing: 12) {
          ForEach(registry.availableShows, id: \.id) { show in
            LightShowCard(
              show: show,
              isSelected: selectedShow?.id == show.id,
              onSelect: {
                selectedShow = show
                showSequenceExpanded = false
              }
            )
          }
        }
        .padding()
      }

      Divider()

      // Configuration area
      if let show = selectedShow {
        VStack(alignment: .leading, spacing: 12) {
          Text("Configuration")
            .font(.headline)

          show.configurationView()

          if let sequencedShow = show as? (any SequencedLightShow), !lightPositions.isEmpty {
            DisclosureGroup(
              isExpanded: $showSequenceExpanded,
              content: {
                LightSequenceList(
                  sequence: sequencedShow.getSequence(for: lightPositions)
                )
              },
              label: {
                HStack {
                  Image(systemName: "list.number")
                  Text("Light Order")
                  Spacer()
                  Text("\(lightPositions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              }
            )
            .padding(.vertical, 4)
          }

          Spacer()

          Button(action: onApply) {
            HStack {
              Image(systemName: "play.fill")
              if show is WaveColorShow {
                Text("Start Wave")
              } else {
                Text("Apply Light Show")
              }
            }
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .disabled(lightPositions.isEmpty)
        }
        .padding()
      } else {
        VStack {
          Spacer()
          Text("Select a light show to configure")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
          Spacer()
        }
        .frame(maxHeight: 200)
      }
    }
  }
}
