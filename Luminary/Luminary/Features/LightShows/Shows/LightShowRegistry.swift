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
  NeonPartyShow(),
      GradientFlowShow(),
      StrobeShow(),
  BassDropShow(),
      TwinkleShow(),
      FireEffectShow(),
      OceanWavesShow(),
      SnakeShow(),
      HauntedSpiritsShow(),
      SoundReactiveShow(),
    ]
  }

  func register(show: any LightShow) {
    availableShows.append(show)
  }
}
