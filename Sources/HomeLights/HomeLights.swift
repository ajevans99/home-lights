import Foundation

/// Primary interface for coordinating HomeLight scenes.
@Observable
public class HomeLights {
  private let homeKitManager: HomeKitManager

  public init() {
    self.homeKitManager = HomeKitManager()
  }

  /// Discovers all HomeKit homes and accessories.
  /// - Parameter completion: Called when discovery is complete
  public func discoverAccessories(completion: @escaping (DiscoveredDevices) -> Void) {
    homeKitManager.discover { result in
      let devices = DiscoveredDevices(from: result)
      completion(devices)
    }
  }

  /// Sets the color of a specific light accessory
  /// - Parameters:
  ///   - accessoryName: The name of the light accessory
  ///   - hue: Hue value (0-360)
  ///   - saturation: Saturation value (0-100)
  ///   - brightness: Brightness value (0-100)
  ///   - completion: Called when the operation completes with success status
  public func setLightColor(
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double,
    completion: @escaping (Bool) -> Void
  ) {
    homeKitManager.setLightColor(
      accessoryName: accessoryName,
      hue: hue,
      saturation: saturation,
      brightness: brightness,
      completion: completion
    )
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
