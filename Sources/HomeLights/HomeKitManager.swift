import Foundation
@preconcurrency import HomeKit

/// Internal wrapper for HomeKit functionality to prevent HomeKit abstractions from leaking.
/// This struct encapsulates all HomeKit-specific logic and provides a clean interface.
struct HomeKitManager: @unchecked Sendable {
  private let homeManager: HMHomeManager

  init() {
    self.homeManager = HMHomeManager()
  }

  /// Discovers and lists all homes, rooms, and accessories.
  /// - Parameter completion: Called when discovery is complete with the discovered items
  func discover(completion: @escaping (DiscoveryResult) -> Void) {
    // HomeKit loads asynchronously, so we need to wait for it to be ready
    let delegate = DiscoveryDelegate { result in
      completion(result)
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
          services: accessory.services.map { $0.name }
        )
      }

      let rooms = home.rooms.map { room in
        let roomAccessories = room.accessories.map { accessory in
          HomeKitManager.DiscoveryResult.HomeInfo.AccessoryInfo(
            name: accessory.name,
            room: accessory.room?.name,
            category: categoryName(for: accessory.category),
            isReachable: accessory.isReachable,
            services: accessory.services.map { $0.name }
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
}
