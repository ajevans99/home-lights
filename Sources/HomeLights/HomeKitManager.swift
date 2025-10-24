import Foundation
@preconcurrency import HomeKit

/// Internal wrapper for HomeKit functionality to prevent HomeKit abstractions from leaking.
/// This struct encapsulates all HomeKit-specific logic and provides a clean interface.
///
/// Light color writes are automatically debounced using `LightWriteQueue` to prevent
/// HomeKit request buildup when users rapidly adjust colors via UI controls.
struct HomeKitManager: @unchecked Sendable {
  private let homeManager: HMHomeManager
  private let writeQueue: LightWriteQueue

  /// Creates a new HomeKit manager with optional debounce configuration
  /// - Parameter debounceInterval: Time to wait before executing light color writes (default: 100ms)
  init(debounceInterval: Duration = .milliseconds(100)) {
    self.homeManager = HMHomeManager()
    self.writeQueue = LightWriteQueue(debounceInterval: debounceInterval)
  }

  /// Discovers and lists all homes, rooms, and accessories.
  /// - Returns: The discovered homes and accessories
  func discover() async -> DiscoveryResult {
    await withCheckedContinuation { continuation in
      let delegate = DiscoveryDelegate { result in
        continuation.resume(returning: result)
      }

      homeManager.delegate = delegate

      // Keep the delegate alive
      objc_setAssociatedObject(
        homeManager,
        "delegate",
        delegate,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /// Sets the color of a specific light accessory with automatic debouncing.
  ///
  /// Multiple rapid calls to the same accessory will cancel previous pending writes,
  /// ensuring only the most recent color values are sent to HomeKit. This prevents
  /// request queue buildup and improves responsiveness.
  ///
  /// Example usage with a color picker:
  /// ```swift
  /// // These rapid calls will be debounced - only the last color is sent
  /// await manager.setLightColor(accessoryName: "Bedroom", hue: 0, saturation: 100, brightness: 100)
  /// await manager.setLightColor(accessoryName: "Bedroom", hue: 60, saturation: 100, brightness: 100)
  /// await manager.setLightColor(accessoryName: "Bedroom", hue: 120, saturation: 100, brightness: 100)
  /// // Only hue: 120 will be sent after the debounce interval
  /// ```
  ///
  /// - Parameters:
  ///   - accessoryName: The name of the light accessory
  ///   - hue: Hue value (0-360)
  ///   - saturation: Saturation value (0-100)
  ///   - brightness: Brightness value (0-100)
  /// - Returns: True if the operation succeeded, false otherwise
  func setLightColor(
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double
  ) async -> Bool {
    await writeQueue.queueWrite(
      accessoryName: accessoryName,
      hue: hue,
      saturation: saturation,
      brightness: brightness
    ) { [homeManager] hue, saturation, brightness in
      await self.performLightColorWrite(
        homeManager: homeManager,
        accessoryName: accessoryName,
        hue: hue,
        saturation: saturation,
        brightness: brightness
      )
    }
  }

  /// Performs the actual HomeKit write operation
  private func performLightColorWrite(
    homeManager: HMHomeManager,
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double
  ) async -> Bool {
    // Find the accessory across all homes
    guard
      let accessory = homeManager.homes.flatMap({ $0.accessories }).first(where: {
        $0.name == accessoryName
      })
    else {
      return false
    }

    // Find the lightbulb service
    guard
      let lightService = accessory.services.first(where: {
        $0.serviceType == HMServiceTypeLightbulb
      })
    else {
      return false
    }

    if hue > 360 || hue < 0 || saturation > 100 || saturation < 0 || brightness > 100
      || brightness < 0
    {
      print("Invalid color values provided! \(hue) H, \(saturation) S, \(brightness) B")
      return false
    }

    // Get characteristic references
    let hueChar = lightService.characteristics.first(where: {
      $0.characteristicType == HMCharacteristicTypeHue
    })
    let satChar = lightService.characteristics.first(where: {
      $0.characteristicType == HMCharacteristicTypeSaturation
    })
    let brightnessChar = lightService.characteristics.first(where: {
      $0.characteristicType == HMCharacteristicTypeBrightness
    })

    // Write all characteristics simultaneously using async/await
    // HomeKit will batch them together when written concurrently
    await withTaskGroup(of: Error?.self) { group in
      if let hueChar = hueChar {
        group.addTask {
          await withCheckedContinuation { continuation in
            hueChar.writeValue(hue) { error in
              continuation.resume(returning: error)
            }
          }
        }
      }

      if let satChar = satChar {
        group.addTask {
          await withCheckedContinuation { continuation in
            satChar.writeValue(saturation) { error in
              continuation.resume(returning: error)
            }
          }
        }
      }

      if let brightnessChar = brightnessChar {
        group.addTask {
          await withCheckedContinuation { continuation in
            brightnessChar.writeValue(brightness) { error in
              continuation.resume(returning: error)
            }
          }
        }
      }

      // Check if any errors occurred
      for await error in group {
        if error != nil {
          return false
        }
      }

      return true
    }

    return true
  }

  /// Cancel all pending light color writes across all accessories.
  ///
  /// Use this when you need to stop all in-flight color changes, such as when
  /// the user navigates away from a control screen or when shutting down.
  func cancelAllWrites() async {
    await writeQueue.cancelAll()
  }

  /// Cancel pending writes for a specific accessory.
  ///
  /// Use this to stop color changes for a single light without affecting other
  /// accessories, such as when hiding controls for one specific light.
  ///
  /// - Parameter accessoryName: The name of the accessory
  func cancelWrites(for accessoryName: String) async {
    await writeQueue.cancel(accessoryName: accessoryName)
  }

  /// Result of HomeKit discovery
  struct DiscoveryResult {
    let homes: [HomeInfo]
    let totalAccessories: Int

    struct HomeInfo {
      let name: String
      let isPrimary: Bool
      let rooms: [RoomInfo]
      let accessories: [AccessoryInfo]

      struct RoomInfo {
        let name: String
        let accessories: [AccessoryInfo]
      }

      struct AccessoryInfo {
        let name: String
        let room: String?
        let category: String
        let isReachable: Bool
        let services: [String]
        let lightColor: LightColor?

        struct LightColor {
          let hue: Double?  // 0-360
          let saturation: Double?  // 0-100
          let brightness: Double?  // 0-100
        }
      }
    }
  }
}

// MARK: - HomeKit Delegate

private class DiscoveryDelegate: NSObject, HMHomeManagerDelegate {
  private let completion: (HomeKitManager.DiscoveryResult) -> Void
  private var hasCompleted = false

  init(completion: @escaping (HomeKitManager.DiscoveryResult) -> Void) {
    self.completion = completion
    super.init()
  }

  func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
    guard !hasCompleted else { return }
    hasCompleted = true

    let result = extractDiscoveryResult(from: manager)
    completion(result)
  }

  private func extractDiscoveryResult(from manager: HMHomeManager) -> HomeKitManager.DiscoveryResult
  {
    let homes = manager.homes.map { home in
      let accessories = home.accessories.map { accessory in
        HomeKitManager.DiscoveryResult.HomeInfo.AccessoryInfo(
          name: accessory.name,
          room: accessory.room?.name,
          category: categoryName(for: accessory.category),
          isReachable: accessory.isReachable,
          services: accessory.services.map { $0.name },
          lightColor: extractLightColor(from: accessory)
        )
      }

      let rooms = home.rooms.map { room in
        let roomAccessories = room.accessories.map { accessory in
          HomeKitManager.DiscoveryResult.HomeInfo.AccessoryInfo(
            name: accessory.name,
            room: accessory.room?.name,
            category: categoryName(for: accessory.category),
            isReachable: accessory.isReachable,
            services: accessory.services.map { $0.name },
            lightColor: extractLightColor(from: accessory)
          )
        }

        return HomeKitManager.DiscoveryResult.HomeInfo.RoomInfo(
          name: room.name,
          accessories: roomAccessories
        )
      }

      return HomeKitManager.DiscoveryResult.HomeInfo(
        name: home.name,
        isPrimary: home == manager.primaryHome,
        rooms: rooms,
        accessories: accessories
      )
    }

    let totalAccessories = homes.reduce(0) { $0 + $1.accessories.count }

    return HomeKitManager.DiscoveryResult(
      homes: homes,
      totalAccessories: totalAccessories
    )
  }

  private func categoryName(for category: HMAccessoryCategory) -> String {
    switch category.categoryType {
    case HMAccessoryCategoryTypeLightbulb: return "Lightbulb"
    case HMAccessoryCategoryTypeSwitch: return "Switch"
    case HMAccessoryCategoryTypeThermostat: return "Thermostat"
    case HMAccessoryCategoryTypeOutlet: return "Outlet"
    case HMAccessoryCategoryTypeFan: return "Fan"
    case HMAccessoryCategoryTypeDoor: return "Door"
    case HMAccessoryCategoryTypeWindow: return "Window"
    case HMAccessoryCategoryTypeGarageDoorOpener: return "Garage Door Opener"
    case HMAccessoryCategoryTypeSecuritySystem: return "Security System"
    case HMAccessoryCategoryTypeSensor: return "Sensor"
    case HMAccessoryCategoryTypeBridge: return "Bridge"
    case HMAccessoryCategoryTypeOther: return "Other"
    default: return "Unknown (\(category.categoryType))"
    }
  }

  private func extractLightColor(from accessory: HMAccessory) -> HomeKitManager.DiscoveryResult
    .HomeInfo
    .AccessoryInfo.LightColor?
  {
    guard accessory.category.categoryType == HMAccessoryCategoryTypeLightbulb else {
      return nil
    }

    // Find the lightbulb service
    guard
      let lightService = accessory.services.first(where: {
        $0.serviceType == HMServiceTypeLightbulb
      })
    else {
      return nil
    }

    var hue: Double?
    var saturation: Double?
    var brightness: Double?

    // Extract hue
    if let hueChar = lightService.characteristics.first(where: {
      $0.characteristicType == HMCharacteristicTypeHue
    }), let hueValue = hueChar.value as? NSNumber {
      hue = hueValue.doubleValue
    }

    // Extract saturation
    if let satChar = lightService.characteristics.first(where: {
      $0.characteristicType == HMCharacteristicTypeSaturation
    }), let satValue = satChar.value as? NSNumber {
      saturation = satValue.doubleValue
    }

    // Extract brightness
    if let brightnessChar = lightService.characteristics.first(where: {
      $0.characteristicType == HMCharacteristicTypeBrightness
    }), let brightnessValue = brightnessChar.value as? NSNumber {
      brightness = brightnessValue.doubleValue
    }

    // Only return if we have at least one value
    if hue != nil || saturation != nil || brightness != nil {
      return HomeKitManager.DiscoveryResult.HomeInfo.AccessoryInfo.LightColor(
        hue: hue,
        saturation: saturation,
        brightness: brightness
      )
    }

    return nil
  }
}
