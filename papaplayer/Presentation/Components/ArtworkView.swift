import AppKit
import SwiftUI

struct ArtworkView: View {
    let track: Track?
    let size: CGFloat
    let colorMode: GameColorMode

    var body: some View {
        if let data = track?.artworkData, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(.white.opacity(0.45), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.34, weight: .heavy))
                        .foregroundStyle(.black.opacity(0.8))
                )
        }
    }

    private var gradientColors: [Color] {
        switch colorMode {
        case .yellow:
            return [.yellow.opacity(0.95), .orange.opacity(0.82)]
        case .blue:
            return [.blue.opacity(0.95), .cyan.opacity(0.82)]
        }
    }
}
