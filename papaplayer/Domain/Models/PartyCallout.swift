import Foundation

struct PartyCallout: Identifiable, Hashable {
    let id: UUID
    let text: String
    let createdTime: Double

    init(id: UUID = UUID(), text: String, createdTime: Double) {
        self.id = id
        self.text = text
        self.createdTime = createdTime
    }
}
