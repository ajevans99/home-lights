import Foundation
import SwiftUI

/// HSB Color representation for HomeKit compatibility
struct HSBColor: Equatable, Codable {
  let hue: Double  // 0-360
  let saturation: Double  // 0-100
  let brightness: Double  // 0-100

  init(hue: Double, saturation: Double, brightness: Double) {
    self.hue = hue
    self.saturation = saturation
    self.brightness = brightness
  }

  init(from color: Color) {
    #if os(macOS)
      let nsColor = NSColor(color)
      var h: CGFloat = 0
      var s: CGFloat = 0
      var b: CGFloat = 0
      var a: CGFloat = 0

      nsColor.usingColorSpace(.deviceRGB)?.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

      self.hue = Double(h) * 360.0
      self.saturation = Double(s) * 100.0
      self.brightness = Double(b) * 100.0
    #else
      let uiColor = UIColor(color)
      var h: CGFloat = 0
      var s: CGFloat = 0
      var b: CGFloat = 0
      var a: CGFloat = 0

      uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

      self.hue = Double(h) * 360.0
      self.saturation = Double(s) * 100.0
      self.brightness = Double(b) * 100.0
    #endif
  }

  var color: Color {
    Color(hue: hue / 360.0, saturation: saturation / 100.0, brightness: brightness / 100.0)
  }
}
