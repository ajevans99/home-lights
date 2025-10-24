import HomeLights
import SwiftUI

struct HomeSelectorMenu: View {
  let devices: DiscoveredDevices
  @Binding var selectedHome: DiscoveredDevices.Home?

  var body: some View {
    Menu {
      ForEach(devices.homes, id: \.name) { home in
        Button(action: { selectedHome = home }) {
          HStack {
            Text(home.name)
            if home.isPrimary {
              Image(systemName: "star.fill")
            }
          }
        }
      }
    } label: {
      HStack {
        Text(selectedHome?.name ?? "Select Home")
        Image(systemName: "chevron.down")
      }
    }
  }
}
