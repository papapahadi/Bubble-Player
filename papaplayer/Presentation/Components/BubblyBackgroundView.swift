import SwiftUI

struct BubblyBackgroundView: View {
    let colorMode: GameColorMode

    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ForEach(0..<11, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? .white.opacity(0.28) : bubbleTint)
                    .frame(width: CGFloat(60 + index * 16), height: CGFloat(60 + index * 16))
                    .offset(
                        x: drift ? CGFloat((index * 21) % 170) - 70 : CGFloat(-((index * 17) % 160)),
                        y: drift ? CGFloat((index * 31) % 440) - 210 : CGFloat(-((index * 29) % 430)) + 180
                    )
                    .blur(radius: CGFloat(index % 5))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                drift.toggle()
            }
        }
    }

    private var gradientColors: [Color] {
        switch colorMode {
        case .yellow:
            return [.yellow.opacity(0.78), .orange.opacity(0.5), .yellow.opacity(0.9)]
        case .blue:
            return [.blue.opacity(0.78), .cyan.opacity(0.5), .blue.opacity(0.9)]
        }
    }

    private var bubbleTint: Color {
        switch colorMode {
        case .yellow: return .orange.opacity(0.18)
        case .blue: return .cyan.opacity(0.18)
        }
    }
}
