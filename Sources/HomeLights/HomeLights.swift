import Foundation

/// Primary interface for coordinating HomeLight scenes.
@Observable
public class HomeLights {
  private let homeKitManager: HomeKitManager

  public init() {
    self.homeKitManager = HomeKitManager()
  }

  /// Discovers all HomeKit homes and accessories.
  /// - Returns: The discovered devices
  public func discoverAccessories() async -> DiscoveredDevices {
    let result = await homeKitManager.discover()
    return DiscoveredDevices(from: result)
  }

  /// Sets the color of a specific light accessory with automatic debouncing.
  ///
  /// Multiple rapid calls to the same accessory will cancel previous pending writes,
  /// ensuring only the most recent color values are sent to HomeKit.
  ///
  /// - Parameters:
  ///   - accessoryName: The name of the light accessory
  ///   - hue: Hue value (0-360)
  ///   - saturation: Saturation value (0-100)
  ///   - brightness: Brightness value (0-100)
  /// - Returns: A task that completes with the write result
  @discardableResult
  public func setLightColor(
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double
  ) -> Task<Bool, Never> {
    homeKitManager.setLightColor(
      accessoryName: accessoryName,
      hue: hue,
      saturation: saturation,
      brightness: brightness
    )
  }

  /// Convenience API that suspends until the write finishes.
  public func setLightColorAndWait(
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double
  ) async -> Bool {
    await setLightColor(
      accessoryName: accessoryName,
      hue: hue,
      saturation: saturation,
      brightness: brightness
    ).value
  }

  /// Cancel all pending light color writes across all accessories.
  public func cancelAllWrites() async {
    await homeKitManager.cancelAllWrites()
  }

  /// Cancel pending writes for a specific accessory.
  /// - Parameter accessoryName: The name of the accessory
  public func cancelWrites(for accessoryName: String) async {
    await homeKitManager.cancelWrites(for: accessoryName)
  }
}

// MARK: - Public Types

/// Discovered HomeKit devices, exposed as a clean public interface
public struct DiscoveredDevices: Codable {
  public let homes: [Home]
  public let totalAccessories: Int

  public struct Home: Codable {
    public let name: String
    public let isPrimary: Bool
    public let rooms: [Room]
    public let accessories: [Accessory]
  }

  public struct Room: Codable {
    public let name: String
    public let accessories: [Accessory]
  }

  public struct Accessory: Codable {
    public let name: String
    public let room: String?
    public let category: String
    public let isReachable: Bool
    public let services: [String]
    public let lightColor: LightColor?

    public struct LightColor: Codable {
      public let hue: Double?  // 0-360
      public let saturation: Double?  // 0-100
      public let brightness: Double?  // 0-100
    }
  }

  init(from result: HomeKitManager.DiscoveryResult) {
    self.homes = result.homes.map { homeInfo in
      Home(
        name: homeInfo.name,
        isPrimary: homeInfo.isPrimary,
        rooms: homeInfo.rooms.map { roomInfo in
          Room(
            name: roomInfo.name,
            accessories: roomInfo.accessories.map { Accessory(from: $0) }
          )
        },
        accessories: homeInfo.accessories.map { Accessory(from: $0) }
      )
    }
    self.totalAccessories = result.totalAccessories
  }
}

extension DiscoveredDevices.Accessory {
  init(from accessoryInfo: HomeKitManager.DiscoveryResult.HomeInfo.AccessoryInfo) {
    self.name = accessoryInfo.name
    self.room = accessoryInfo.room
    self.category = accessoryInfo.category
    self.isReachable = accessoryInfo.isReachable
    self.services = accessoryInfo.services
    self.lightColor =
      accessoryInfo.lightColor.map {
        LightColor(
          hue: $0.hue,
          saturation: $0.saturation,
          brightness: $0.brightness
        )
      }
  }
}
