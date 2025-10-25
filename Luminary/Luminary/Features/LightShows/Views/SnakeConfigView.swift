import SwiftUI

struct SnakeConfigView: View {
  @Bindable var show: SnakeShow

  var body: some View {
    Form {
      Section("Snake Appearance") {
        ColorPicker("Snake Color", selection: $show.snakeColor)
        ColorPicker("Background Color", selection: $show.backgroundColor)

        HStack {
          Text("Tail Length")
          Spacer()
          Stepper("\(show.tailLength)", value: $show.tailLength, in: 2...10)
            .labelsHidden()
          Text("\(show.tailLength)")
            .foregroundStyle(.secondary)
            .frame(width: 30, alignment: .trailing)
        }
      }

      Section("Movement") {
        VStack(alignment: .leading) {
          Text("Speed")
          HStack {
            Text("Fast")
              .font(.caption)
              .foregroundStyle(.secondary)
            Slider(value: $show.speed, in: 0.1...2.0)
            Text("Slow")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Text(String(format: "%.1f seconds per move", show.speed))
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Picker("Ordering", selection: $show.orderingStrategy) {
          ForEach(LightOrderingStrategy.allCases) { strategy in
            Label(strategy.rawValue, systemImage: strategy.icon)
              .tag(strategy)
          }
        }

        Text(show.orderingStrategy.description)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section {
        Text(
          "The snake will slither across your lights with a fading tail effect. It automatically navigates the space based on your light layout."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  SnakeConfigView(show: SnakeShow())
}
