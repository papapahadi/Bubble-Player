import Combine
import Foundation
import SwiftUI

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var currentIndex: Int?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Float = 0.9 {
        didSet { playbackService.setVolume(volume) }
    }
    @Published var shuffleEnabled = false
    @Published var repeatMode: RepeatMode = .all
    @Published var libraryFilter: LibraryFilter = .all
    @Published var appColorMode: GameColorMode = .yellow
    @Published var gameModeEnabled = false
    @Published var rhythmNotes: [RhythmNote] = []
    @Published var gameScore = 0
    @Published var gameCombo = 0
    @Published var gameHighCombo = 0
    @Published var gameMisses = 0
    @Published var bubbleDangerFill: Double = 0
    @Published var gameLost = false
    @Published var partyCallouts: [PartyCallout] = []
    @Published var honeySplashes: [HoneySplash] = []
    @Published var honeyRipples: [HoneyRipple] = []

    private let importService: TrackImporting
    private let playbackService: AudioPlaybackControlling
    private let laneCount = 4
    private let minBubbleSize = 24.0
    private let maxBubbleSize = 64.0
    private let minTravelDuration = 2.2
    private let maxTravelDuration = 4.2
    private let targetZoneRatio = 0.82
    private let maxDangerFill = 1.0
    private let splashLifetime = 0.55
    private let rippleLifetime = 1.35
    private let calloutLifetime = 2.8
    private var lastSpawnTime = 0.0
    private var latestEnergy = 0.0
    private var lastCalloutLevelBucket = -1
    private var lastCalloutTime = 0.0

    init(
        importService: TrackImporting? = nil,
        playbackService: AudioPlaybackControlling? = nil
    ) {
        self.importService = importService ?? TrackImportService()
        self.playbackService = playbackService ?? AudioPlaybackService()

        self.playbackService.onTimeUpdate = { [weak self] time, duration in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time
                self.duration = duration
                self.advanceGame(at: time)
            }
        }

        self.playbackService.onAudioEnergy = { [weak self] energy in
            guard let self else { return }
            Task { @MainActor in
                self.latestEnergy = energy
            }
        }

        self.playbackService.onTrackFinished = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.handleTrackFinished()
            }
        }
    }

    var currentTrack: Track? {
        guard let index = currentIndex, tracks.indices.contains(index) else { return nil }
        return tracks[index]
    }

    func filteredTracks(_ query: String) -> [Track] {
        let base = baseLibrary(for: libraryFilter)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }

        return base.filter { track in
            track.title.localizedCaseInsensitiveContains(trimmed) ||
            track.artist.localizedCaseInsensitiveContains(trimmed) ||
            track.album.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func importFromProviders(_ providers: [NSItemProvider]) {
        importService.decodeFileURLs(from: providers) { [weak self] urls in
            Task { @MainActor in
                self?.importTracks(from: urls)
            }
        }
    }

    func importTracks(from urls: [URL]) {
        let imported = importService.importTracks(from: urls)
        let existingIDs = Set(tracks.map(\.id))
        let deduplicated = imported.filter { !existingIDs.contains($0.id) }
        tracks.append(contentsOf: deduplicated)

        if currentIndex == nil, !tracks.isEmpty {
            loadTrack(at: 0, autoplay: false)
        }
    }

    func playPause() {
        guard currentTrack != nil else {
            if !tracks.isEmpty {
                loadTrack(at: currentIndex ?? 0, autoplay: true)
            }
            return
        }

        isPlaying = playbackService.playPause()
    }

    func play(track: Track) {
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        loadTrack(at: index, autoplay: true)
    }

    func toggleFavorite(_ track: Track) {
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[index].isFavorite.toggle()
    }

    func toggleCurrentFavorite() {
        guard let index = currentIndex, tracks.indices.contains(index) else { return }
        tracks[index].isFavorite.toggle()
    }

    func next() {
        guard !tracks.isEmpty else { return }

        if shuffleEnabled {
            loadTrack(at: Int.random(in: 0..<tracks.count), autoplay: true)
            return
        }

        if let index = currentIndex, index + 1 < tracks.count {
            loadTrack(at: index + 1, autoplay: true)
        } else if repeatMode == .all {
            loadTrack(at: 0, autoplay: true)
        }
    }

    func previous() {
        guard !tracks.isEmpty else { return }

        if currentTime > 3 {
            seek(to: 0)
            return
        }

        if let index = currentIndex, index > 0 {
            loadTrack(at: index - 1, autoplay: true)
        } else if repeatMode == .all {
            loadTrack(at: tracks.count - 1, autoplay: true)
        }
    }

    func cycleRepeatMode() {
        repeatMode = switch repeatMode {
        case .off: .all
        case .all: .one
        case .one: .off
        }
    }

    func toggleGameMode() {
        gameModeEnabled.toggle()
        resetRhythmGameState(keepEnabled: true)
    }

    func restartGameRound() {
        guard gameModeEnabled, currentTrack != nil else { return }
        resetRhythmGameState(keepEnabled: true)
        seek(to: 0)
        if let index = currentIndex {
            loadTrack(at: index, autoplay: true, shouldCountPlay: false)
        }
    }

    func hitNote(_ id: UUID) {
        guard gameModeEnabled, !gameLost else { return }
        guard let index = rhythmNotes.firstIndex(where: { $0.id == id }) else { return }

        let note = rhythmNotes[index]
        createSplash(from: note)
        let noteSize = rhythmNotes[index].size
        gameCombo += 1
        gameHighCombo = max(gameHighCombo, gameCombo)
        gameScore += Int(25 + noteSize * 2)
        rhythmNotes.remove(at: index)
    }

    func hitNearestNote(in lane: Int) {
        guard gameModeEnabled, !gameLost else { return }
        let laneNotes = rhythmNotes.enumerated().filter { $0.element.lane == lane }
        guard let candidate = laneNotes.min(by: {
            noteTargetTime(for: $0.element) < noteTargetTime(for: $1.element)
        }) else {
            return
        }
        hitNote(candidate.element.id)
    }

    func seek(to time: Double) {
        playbackService.seek(to: time)
        currentTime = time
        if gameModeEnabled {
            resetRhythmGameState(keepEnabled: true)
        }
    }

    func formattedTime(_ time: Double) -> String {
        guard time.isFinite else { return "0:00" }
        let totalSeconds = max(Int(time), 0)
        return "\(totalSeconds / 60):" + String(format: "%02d", totalSeconds % 60)
    }

    private func loadTrack(at index: Int, autoplay: Bool, shouldCountPlay: Bool = true) {
        guard tracks.indices.contains(index) else { return }

        do {
            currentIndex = index
            duration = try playbackService.load(url: tracks[index].url, autoplay: autoplay, volume: volume)
            currentTime = 0
            if gameModeEnabled {
                resetRhythmGameState(keepEnabled: true)
            }

            if autoplay {
                if shouldCountPlay {
                    tracks[index].playCount += 1
                    tracks[index].lastPlayed = Date()
                }
                isPlaying = true
            } else {
                isPlaying = false
            }
        } catch {
            isPlaying = false
        }
    }

    private func handleTrackFinished() {
        if repeatMode == .one {
            seek(to: 0)
            playbackService.resume()
            isPlaying = true
            return
        }

        next()
    }

    private func advanceGame(at time: Double) {
        guard gameModeEnabled, isPlaying, !gameLost else { return }

        honeySplashes.removeAll { time - $0.createdTime > splashLifetime }
        honeyRipples.removeAll { time - $0.createdTime > rippleLifetime }
        partyCallouts.removeAll { time - $0.createdTime > calloutLifetime }

        let expiredNotes = rhythmNotes.filter { time > noteTargetTime(for: $0) }
        if !expiredNotes.isEmpty {
            for note in expiredNotes {
                registerMiss(for: note)
            }
            rhythmNotes.removeAll { time > noteTargetTime(for: $0) }
        }

        let intensity = max(latestEnergy, 0.1)
        let spawnInterval = max(0.45, 1.0 - intensity * 0.4)
        if time - lastSpawnTime >= spawnInterval, intensity > 0.15 {
            let lane = Int.random(in: 0..<laneCount)
            let size = Double.random(in: minBubbleSize...maxBubbleSize)
            let durationFactor = (maxBubbleSize - size) / (maxBubbleSize - minBubbleSize)
            let travelDuration = minTravelDuration + durationFactor * (maxTravelDuration - minTravelDuration)
            rhythmNotes.append(
                RhythmNote(
                    lane: lane,
                    spawnTime: time,
                    size: size,
                    travelDuration: travelDuration
                )
            )
            lastSpawnTime = time
        }
    }

    private func noteTargetTime(for note: RhythmNote) -> Double {
        note.spawnTime + note.travelDuration
    }

    private func registerMiss(for note: RhythmNote) {
        let previousFill = bubbleDangerFill
        gameMisses += 1
        gameCombo = 0
        bubbleDangerFill = min(maxDangerFill, bubbleDangerFill + bubbleFillImpact(for: note))
        createRipple(lane: note.lane, strength: 0.9 + (note.size / maxBubbleSize) * 0.8)
        maybeCreatePartyCallout(previousFill: previousFill, newFill: bubbleDangerFill)

        if bubbleDangerFill >= maxDangerFill {
            gameLost = true
            isPlaying = false
            addPartyCallout("Party got over. Speakers got drowned.")
            playbackService.fadeOutAndStop(duration: 3.6)
        }
    }

    private func bubbleFillImpact(for note: RhythmNote) -> Double {
        // Larger bubbles penalize more when they are missed.
        let normalizedSize = (note.size - minBubbleSize) / (maxBubbleSize - minBubbleSize)
        return 0.02 + normalizedSize * 0.055
    }

    private func resetRhythmGameState(keepEnabled: Bool) {
        rhythmNotes = []
        gameScore = 0
        gameCombo = 0
        gameHighCombo = 0
        gameMisses = 0
        bubbleDangerFill = 0
        gameLost = false
        partyCallouts = []
        honeySplashes = []
        honeyRipples = []
        lastSpawnTime = currentTime
        latestEnergy = 0
        lastCalloutLevelBucket = -1
        lastCalloutTime = 0
        if !keepEnabled {
            gameModeEnabled = false
        }
    }

    var rhythmLaneCount: Int { laneCount }
    var rhythmTargetZoneRatio: Double { targetZoneRatio }

    private func createSplash(from note: RhythmNote) {
        let progress = min(max((currentTime - note.spawnTime) / note.travelDuration, 0), 1)
        honeySplashes.append(
            HoneySplash(
                lane: note.lane,
                progress: progress,
                size: note.size,
                createdTime: currentTime
            )
        )
        createRipple(lane: note.lane, strength: 0.45 + (note.size / maxBubbleSize) * 0.5)
    }

    private func createRipple(lane: Int, strength: Double) {
        honeyRipples.append(
            HoneyRipple(
                lane: lane,
                strength: strength,
                createdTime: currentTime
            )
        )
    }

    private func maybeCreatePartyCallout(previousFill: Double, newFill: Double) {
        guard newFill > previousFill else { return }
        let bucket = fillBucket(for: newFill)
        guard bucket > 0 else { return }

        let crossedIntoNewBucket = bucket > lastCalloutLevelBucket
        let cooldownPassed = currentTime - lastCalloutTime > 1.6
        guard crossedIntoNewBucket || cooldownPassed else { return }

        addPartyCallout(randomCallout(for: bucket))
        lastCalloutLevelBucket = max(lastCalloutLevelBucket, bucket)
        lastCalloutTime = currentTime
    }

    private func addPartyCallout(_ text: String) {
        partyCallouts.append(
            PartyCallout(
                text: text,
                createdTime: currentTime
            )
        )
    }

    private func fillBucket(for fill: Double) -> Int {
        if fill >= 0.85 { return 4 }
        if fill >= 0.65 { return 3 }
        if fill >= 0.45 { return 2 }
        if fill >= 0.22 { return 1 }
        return 0
    }

    private func randomCallout(for bucket: Int) -> String {
        let lines: [String]
        switch bucket {
        case 1:
            lines = [
                "Crowd's getting loud, keep the floor clear!",
                "Water creeping in, but the party's still on!",
                "Speakers are filling up! This party can't get over this soon."
            ]
        case 2:
            lines = [
                "The bass is wobbling, pop faster!",
                "DJ says move, the deck's getting wet!",
                "The vibe is slipping, save the speakers!"
            ]
        case 3:
            lines = [
                "We're close to a shutdown, clear those bubbles!",
                "Party alert: speakers almost flooded!",
                "This dance floor is seconds from silence!"
            ]
        default:
            lines = [
                "Final warning! Save the party now!",
                "Speakers are choking on water!",
                "One more miss and this party is over!"
            ]
        }

        return lines.randomElement() ?? "Keep the party alive!"
    }

    private func baseLibrary(for filter: LibraryFilter) -> [Track] {
        switch filter {
        case .all:
            return tracks
        case .favorites:
            return tracks.filter(\.isFavorite)
        case .recentlyAdded:
            return tracks.sorted { $0.dateAdded > $1.dateAdded }
        case .mostPlayed:
            return tracks.sorted {
                if $0.playCount == $1.playCount {
                    return ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast)
                }
                return $0.playCount > $1.playCount
            }
        }
    }
}
