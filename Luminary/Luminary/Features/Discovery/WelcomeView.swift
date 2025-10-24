import SwiftUI

struct WelcomeView: View {
  let errorMessage: String?
  let onDiscover: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "lightbulb.fill")
        .imageScale(.large)
        .font(.system(size: 60))
        .foregroundStyle(.tint)

      Text("Home Lights")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("Discover and control your HomeKit devices")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button("Discover Devices") {
        onDiscover()
      }
      .buttonStyle(.borderedProminent)
      .padding(.top)

      if let errorMessage = errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
          .multilineTextAlignment(.center)
          .padding()
      }
    }
    .padding()
  }
}
