import Foundation

enum RepeatMode {
    case off
    case all
    case one

    var symbolName: String {
        switch self {
        case .off: "repeat"
        case .all: "repeat.circle.fill"
        case .one: "repeat.1.circle.fill"
        }
    }
}
