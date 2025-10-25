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
      AlternatingColorsShow(),
      WaveColorShow(),
      RainbowWaveShow(),
      ColorPulseShow(),
      GradientFlowShow(),
      StrobeShow(),
      TwinkleShow(),
      FireEffectShow(),
      OceanWavesShow(),
      SnakeShow(),
      SoundReactiveShow(),
    ]
  }

  func register(show: any LightShow) {
    availableShows.append(show)
  }
}
