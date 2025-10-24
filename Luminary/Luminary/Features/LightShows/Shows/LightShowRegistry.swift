import Foundation
import SwiftUI

@Observable
class LightShowRegistry {
  var availableShows: [any LightShow] = []
  var currentShow: (any LightShow)?

  init() {
    registerDefaultShows()
  }

  private func registerDefaultShows() {
    availableShows = [
      SolidColorShow(),
      WaveColorShow(),
      RainbowWaveShow(),
      ColorPulseShow(),
      GradientFlowShow(),
      StrobeShow(),
      TwinkleShow(),
      FireEffectShow(),
      OceanWavesShow(),
    ]
  }

  func register(show: any LightShow) {
    availableShows.append(show)
  }
}
