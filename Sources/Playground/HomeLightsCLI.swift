import ArgumentParser
import Foundation
import HomeLights

@available(macCatalyst 18, *)
@main
struct HomeLightsCLI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "home-lights",
    abstract: "A utility for discovering and controlling HomeKit devices",
    version: "0.1.0",
    subcommands: [Discover.self],
    defaultSubcommand: Discover.self
  )
}

// MARK: - Discover Command

@available(macCatalyst 18, *)
extension HomeLightsCLI {
  struct Discover: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Discover all HomeKit devices and accessories"
    )

    @Flag(name: .shortAndLong, help: "Show detailed information about each accessory")
    var verbose = false

    @Flag(name: .long, help: "Output in JSON format")
    var json = false

    func run() async throws {
      print("🔍 Discovering HomeKit devices...")
      print("⏳ Please wait while we scan your home...\n")

      let homeLights = HomeLights()
      let verbose = self.verbose
      let json = self.json

      await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        homeLights.discoverAccessories { devices in
          if json {
            Self.printJSON(devices: devices)
          } else {
            Self.printFormatted(devices: devices, verbose: verbose)
          }
          continuation.resume()
        }
      }
    }

    private static func printFormatted(devices: DiscoveredDevices, verbose: Bool) {
      print("✅ Discovery complete!\n")

      if devices.homes.isEmpty {
        print("⚠️  No homes found. Make sure you have:")
        print("   1. Set up HomeKit devices")
        print("   2. Granted Home access to this app")
        print("   3. Signed in to iCloud on this Mac")
        return
      }

      print("📊 Summary:")
      print("   Homes: \(devices.homes.count)")
      print("   Total Accessories: \(devices.totalAccessories)\n")

      for home in devices.homes {
        let primaryIndicator = home.isPrimary ? " ⭐" : ""
        print("🏠 \(home.name)\(primaryIndicator)")

        if home.rooms.isEmpty && home.accessories.isEmpty {
          print("   (No rooms or accessories)")
          continue
        }

        if !home.rooms.isEmpty {
          print("\n   Rooms (\(home.rooms.count)):")
          for room in home.rooms {
            print("   📍 \(room.name)")

            if verbose {
              for accessory in room.accessories {
                Self.printAccessory(accessory, indent: "      ")
              }
            } else if !room.accessories.isEmpty {
              print("      \(room.accessories.count) accessory(ies)")
            }
          }
        }

        if !home.accessories.isEmpty {
          print("\n   All Accessories (\(home.accessories.count)):")
          for accessory in home.accessories {
            if verbose {
              Self.printAccessory(accessory, indent: "   ")
            } else {
              let status = accessory.isReachable ? "✓" : "✗"
              print("   [\(status)] \(accessory.name) (\(accessory.category))")
            }
          }
        }

        print()
      }
    }

    private static func printAccessory(_ accessory: DiscoveredDevices.Accessory, indent: String) {
      let status = accessory.isReachable ? "✓" : "✗"
      print("\(indent)[\(status)] \(accessory.name)")
      print("\(indent)   Category: \(accessory.category)")
      if let room = accessory.room {
        print("\(indent)   Room: \(room)")
      }
      print("\(indent)   Reachable: \(accessory.isReachable ? "Yes" : "No")")
      if !accessory.services.isEmpty {
        print("\(indent)   Services: \(accessory.services.joined(separator: ", "))")
      }
    }

    private static func printJSON(devices: DiscoveredDevices) {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

      let jsonData: [String: Any] = [
        "homes": devices.homes.map { home in
          [
            "name": home.name,
            "isPrimary": home.isPrimary,
            "rooms": home.rooms.map { room in
              [
                "name": room.name,
                "accessories": room.accessories.map { Self.accessoryToDict($0) },
              ]
            },
            "accessories": home.accessories.map { Self.accessoryToDict($0) },
          ]
        },
        "totalAccessories": devices.totalAccessories,
      ]

      if let jsonData = try? JSONSerialization.data(
        withJSONObject: jsonData,
        options: [.prettyPrinted, .sortedKeys]
      ),
        let jsonString = String(data: jsonData, encoding: .utf8)
      {
        print(jsonString)
      }
    }

    private static func accessoryToDict(_ accessory: DiscoveredDevices.Accessory) -> [String: Any] {
      var dict: [String: Any] = [
        "name": accessory.name,
        "category": accessory.category,
        "isReachable": accessory.isReachable,
        "services": accessory.services,
      ]
      if let room = accessory.room {
        dict["room"] = room
      }
      return dict
    }
  }
}
