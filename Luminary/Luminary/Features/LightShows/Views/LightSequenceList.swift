import SwiftUI

struct LightSequenceList: View {
  let sequence: [String]

  var body: some View {
    VStack(spacing: 8) {
      ForEach(Array(sequence.enumerated()), id: \.element) { index, lightName in
        HStack(spacing: 12) {
          ZStack {
            Circle()
              .fill(Color.accentColor)
              .frame(width: 24, height: 24)

            Text("\(index + 1)")
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundColor(.white)
          }

          HStack {
            Image(systemName: "lightbulb.fill")
              .font(.caption)
              .foregroundColor(.yellow)

            Text(lightName)
              .font(.caption)
              .lineLimit(1)

            Spacer()
          }
        }
        .padding(.vertical, 4)
      }
    }
    .padding(.top, 8)
  }
}
