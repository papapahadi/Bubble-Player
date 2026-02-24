import Foundation

struct HoneyRipple: Identifiable, Hashable {
    let id: UUID
    let lane: Int
    let strength: Double
    let createdTime: Double

    init(
        id: UUID = UUID(),
        lane: Int,
        strength: Double,
        createdTime: Double
    ) {
        self.id = id
        self.lane = lane
        self.strength = strength
        self.createdTime = createdTime
    }
}
