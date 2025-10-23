import Foundation

/// Primary interface for coordinating HomeLight scenes.
public struct HomeLights {
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
