import Foundation
import UniformTypeIdentifiers

extension URL {
    var isAudioFile: Bool {
        guard let type = UTType(filenameExtension: pathExtension.lowercased()) else { return false }
        return type.conforms(to: .audio)
    }
}

extension UTType {
    static var mp3: UTType {
        UTType(filenameExtension: "mp3") ?? .audio
    }

    static var wav: UTType {
        UTType(filenameExtension: "wav") ?? .audio
    }
}
