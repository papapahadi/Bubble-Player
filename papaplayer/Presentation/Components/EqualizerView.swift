import SwiftUI

struct EqualizerView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(.black.opacity(0.75))
                        .frame(width: 4, height: CGFloat(15 + abs(sin(t * 3 + Double(index))) * 30))
                }
            }
            .padding(12)
            .background(.white.opacity(0.2), in: Capsule())
        }
    }
}
