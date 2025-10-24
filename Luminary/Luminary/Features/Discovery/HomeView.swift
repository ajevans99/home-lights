import HomeLights
import SwiftUI

struct HomeView: View {
  let home: DiscoveredDevices.Home

  var body: some View {
    VStack {
      List {
        ForEach(home.rooms, id: \.name) { room in
          DisclosureGroup {
            ForEach(room.accessories, id: \.name) { accessory in
              AccessoryRow(accessory: accessory)
            }
          } label: {
            HStack {
              Image(systemName: "door.left.hand.open")
              Text(room.name)
              Spacer()
              Text("\(room.accessories.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }
      }

      NavigationLink(destination: LightCanvasView(home: home)) {
        HStack {
          Image(systemName: "rectangle.on.rectangle.angled")
          Text("Open Light Canvas")
          Spacer()
          Image(systemName: "chevron.right")
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
      }
      .padding()
    }
  }
}
