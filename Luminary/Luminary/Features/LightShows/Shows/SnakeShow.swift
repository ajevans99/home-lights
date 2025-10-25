import Foundation
import SwiftUI

@Observable
class SnakeShow: LightShow {
  let id = "snake"
  let name = "Snake"
  let description = "A colorful snake slithers across your lights"
  let icon = "arrow.turn.up.right"

  var snakeColor: Color = .green
  var backgroundColor: Color = .black
  var speed: Double = 0.5  // seconds per move
  var tailLength: Int = 5
  var orderingStrategy: LightOrderingStrategy = .nearestNeighbor

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(SnakeConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      guard !lights.isEmpty else { return }

      // Determine ordered lights based on the chosen strategy
      let orderedLights = makeOrderedLights(from: lights)
      guard !orderedLights.isEmpty else { return }

      // Initialize all lights to the background color
      let initialBackground = HSBColor(from: backgroundColor)
      var initialWrites: [Task<Bool, Never>] = []
      for light in orderedLights {
        onColorUpdate(light.name, initialBackground)
        initialWrites.append(
          controller.setLightColor(
            accessoryName: light.name,
            hue: initialBackground.hue,
            saturation: initialBackground.saturation,
            brightness: initialBackground.brightness
          )
        )
      }

      for task in initialWrites {
        _ = await task.value
      }

      var headIndex = 0
      var snakeIndices: [Int] = [headIndex]
      var moveCounter = 0
      var movingForward = true

      try? await Task.sleep(for: .seconds(0.5))

      while !Task.isCancelled {
        moveCounter += 1

        let currentSnakeColor = HSBColor(from: snakeColor)
        let currentBackgroundColor = HSBColor(from: backgroundColor)
        let segmentLimit = min(max(1, tailLength), orderedLights.count)

        if orderedLights.count > 1 {
          if moveCounter.isMultiple(of: 12) {
            movingForward = Bool.random()
          }

          let step = movingForward ? 1 : -1
          headIndex = (headIndex + step + orderedLights.count) % orderedLights.count

          if let existingIndex = snakeIndices.firstIndex(of: headIndex) {
            snakeIndices.remove(at: existingIndex)
          }

          snakeIndices.insert(headIndex, at: 0)
        }

        while snakeIndices.count > segmentLimit {
          let removedIndex = snakeIndices.removeLast()
          let tailLight = orderedLights[removedIndex]
          onColorUpdate(tailLight.name, currentBackgroundColor)
          _ = await controller.setLightColorAndWait(
            accessoryName: tailLight.name,
            hue: currentBackgroundColor.hue,
            saturation: currentBackgroundColor.saturation,
            brightness: currentBackgroundColor.brightness
          )
        }

        var segmentWrites: [Task<Bool, Never>] = []
        for (offset, lightIndex) in snakeIndices.enumerated() {
          guard offset < segmentLimit else { break }

          let light = orderedLights[lightIndex]
          let fade = max(0.05, 1.0 - (Double(offset) / Double(segmentLimit)))
          let brightness = max(10, currentSnakeColor.brightness * fade)
          let segmentColor = HSBColor(
            hue: currentSnakeColor.hue,
            saturation: currentSnakeColor.saturation,
            brightness: brightness
          )

          onColorUpdate(light.name, segmentColor)
          segmentWrites.append(
            controller.setLightColor(
              accessoryName: light.name,
              hue: segmentColor.hue,
              saturation: segmentColor.saturation,
              brightness: segmentColor.brightness
            )
          )
        }

        for task in segmentWrites {
          _ = await task.value
        }

        let delay = max(0.05, speed)
        try? await Task.sleep(for: .seconds(delay))
      }
    }
  }

  private func makeOrderedLights(from lights: [(name: String, position: CGPoint)])
    -> [(name: String, position: CGPoint)]
  {
    let sequence = orderingStrategy.calculateSequence(lights: lights)
    var seen = Set<String>()
    var ordered: [(name: String, position: CGPoint)] = []

    let lookup = Dictionary(uniqueKeysWithValues: lights.map { ($0.name, $0.position) })

    for name in sequence where seen.insert(name).inserted {
      if let position = lookup[name] {
        ordered.append((name: name, position: position))
      }
    }

    if ordered.count < lights.count {
      for entry in lights where !seen.contains(entry.name) {
        ordered.append(entry)
        seen.insert(entry.name)
      }
    }

    return ordered
  }
}
