import Foundation

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all
    case favorites
    case recentlyAdded
    case mostPlayed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .favorites: "Favorites"
        case .recentlyAdded: "Recent"
        case .mostPlayed: "Top"
        }
    }
}
