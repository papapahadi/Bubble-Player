import Foundation

struct RhythmNote: Identifiable, Hashable {
    let id: UUID
    let lane: Int
    let spawnTime: Double
    let size: Double
    let travelDuration: Double

    init(
        id: UUID = UUID(),
        lane: Int,
        spawnTime: Double,
        size: Double,
        travelDuration: Double
    ) {
        self.id = id
        self.lane = lane
        self.spawnTime = spawnTime
        self.size = size
        self.travelDuration = travelDuration
    }
}
