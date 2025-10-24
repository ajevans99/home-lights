import HomeLights
import SwiftUI

@main
struct LuminaryApp: App {
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
