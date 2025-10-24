import SwiftUI

struct SolidColorConfigView: View {
  @Bindable var show: SolidColorShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Select Color")
        .font(.headline)

      ColorPicker("Color", selection: $show.selectedColor)
        .labelsHidden()
        .frame(height: 200)

      Text("This will set all lights to the selected color")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}
