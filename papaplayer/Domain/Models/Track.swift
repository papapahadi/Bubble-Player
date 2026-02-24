import Foundation

struct Track: Identifiable, Hashable {
    let id: String
    let url: URL
    var title: String
    var artist: String
    var album: String
    var artworkData: Data?
    var dateAdded: Date
    var isFavorite: Bool
    var playCount: Int
    var lastPlayed: Date?

    init(
        url: URL,
        title: String,
        artist: String,
        album: String,
        artworkData: Data?,
        dateAdded: Date,
        isFavorite: Bool = false,
        playCount: Int = 0,
        lastPlayed: Date? = nil
    ) {
        self.id = url.path
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkData = artworkData
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
        self.playCount = playCount
        self.lastPlayed = lastPlayed
    }
}
