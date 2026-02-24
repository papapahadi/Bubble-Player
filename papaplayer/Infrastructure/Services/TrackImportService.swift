import AVFoundation
import Foundation
import UniformTypeIdentifiers

protocol TrackImporting {
    func decodeFileURLs(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void)
    func importTracks(from urls: [URL]) -> [Track]
}

final class TrackImportService: TrackImporting {
    func decodeFileURLs(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        let lock = NSLock()
        var urls: [URL] = []

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                defer { group.leave() }
                guard let data else { return }
                let nsURL = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil)
                lock.lock()
                urls.append(nsURL as URL)
                lock.unlock()
            }
        }

        group.notify(queue: .main) {
            completion(urls)
        }
    }

    func importTracks(from urls: [URL]) -> [Track] {
        let expandedURLs = expandedAudioFiles(from: urls)

        return expandedURLs.compactMap { sourceURL in
            guard let localURL = makePersistentCopy(of: sourceURL) else { return nil }
            let metadata = metadataFromFile(localURL)
            return Track(
                url: localURL,
                title: metadata.title,
                artist: metadata.artist,
                album: metadata.album,
                artworkData: metadata.artworkData,
                dateAdded: Date()
            )
        }
    }

    private func expandedAudioFiles(from urls: [URL]) -> [URL] {
        var audioURLs: [URL] = []
        let fileManager = FileManager.default

        for url in urls {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator where fileURL.isAudioFile {
                        audioURLs.append(fileURL)
                    }
                }
            } else if url.isAudioFile {
                audioURLs.append(url)
            }
        }

        return audioURLs
    }

    private func metadataFromFile(_ url: URL) -> TrackMetadata {
        let asset = AVAsset(url: url)
        let metadata = asset.commonMetadata

        let title = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierTitle).first?.stringValue
        let artist = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtist).first?.stringValue
        let album = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierAlbumName).first?.stringValue
        let artworkData = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork).first?.dataValue

        let fallbackTitle = url.deletingPathExtension().lastPathComponent

        return TrackMetadata(
            title: (title?.isEmpty == false) ? title! : fallbackTitle,
            artist: (artist?.isEmpty == false) ? artist! : "Unknown Artist",
            album: (album?.isEmpty == false) ? album! : "",
            artworkData: artworkData
        )
    }

    private func makePersistentCopy(of sourceURL: URL) -> URL? {
        let access = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if access { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let fileManager = FileManager.default
        do {
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }

            let destinationURL = documentsURL.appendingPathComponent(sourceURL.lastPathComponent)
            if !fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }

            return destinationURL
        } catch {
            return nil
        }
    }
}
