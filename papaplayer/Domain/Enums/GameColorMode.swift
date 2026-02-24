import Foundation

enum GameColorMode: String, CaseIterable, Identifiable {
    case yellow
    case blue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yellow: "Yellow"
        case .blue: "Blue"
        }
    }
}
