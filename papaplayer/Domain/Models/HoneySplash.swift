import Foundation

struct HoneySplash: Identifiable, Hashable {
    let id: UUID
    let lane: Int
    let progress: Double
    let size: Double
    let createdTime: Double

    init(
        id: UUID = UUID(),
        lane: Int,
        progress: Double,
        size: Double,
        createdTime: Double
    ) {
        self.id = id
        self.lane = lane
        self.progress = progress
        self.size = size
        self.createdTime = createdTime
    }
}
