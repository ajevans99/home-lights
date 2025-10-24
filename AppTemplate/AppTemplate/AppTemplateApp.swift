import HomeLights
import SwiftUI

@main
struct AppTemplateApp: App {
  @State private var homeLights = HomeLights()
  @State private var lightShowRegistry = LightShowRegistry()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(homeLights)
        .environment(lightShowRegistry)
    }
  }
}
