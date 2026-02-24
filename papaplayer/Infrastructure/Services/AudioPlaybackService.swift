import AVFoundation
import Foundation

protocol AudioPlaybackControlling: AnyObject {
    var onTimeUpdate: ((Double, Double) -> Void)? { get set }
    var onTrackFinished: (() -> Void)? { get set }
    var onAudioEnergy: ((Double) -> Void)? { get set }

    func load(url: URL, autoplay: Bool, volume: Float) throws -> Double
    func playPause() -> Bool
    func seek(to time: Double)
    func setVolume(_ value: Float)
    func stop()
    func fadeOutAndStop(duration: Double)
    func resume()
    func currentPlaybackTime() -> Double
}

final class AudioPlaybackService: NSObject, AudioPlaybackControlling, AVAudioPlayerDelegate {
    var onTimeUpdate: ((Double, Double) -> Void)?
    var onTrackFinished: (() -> Void)?
    var onAudioEnergy: ((Double) -> Void)?

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var fadeTimer: Timer?

    func load(url: URL, autoplay: Bool, volume: Float) throws -> Double {
        stopTimer()
        stopFadeTimer()

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        player.isMeteringEnabled = true
        player.prepareToPlay()
        player.volume = volume
        audioPlayer = player

        if autoplay {
            player.play()
        }

        startTimer()
        return player.duration
    }

    func playPause() -> Bool {
        guard let player = audioPlayer else { return false }
        stopFadeTimer()

        if player.isPlaying {
            player.pause()
            return false
        }

        player.play()
        return true
    }

    func seek(to time: Double) {
        audioPlayer?.currentTime = time
        guard let player = audioPlayer else { return }
        onTimeUpdate?(player.currentTime, max(player.duration, 1))
    }

    func setVolume(_ value: Float) {
        audioPlayer?.volume = value
    }

    func stop() {
        audioPlayer?.stop()
        stopTimer()
        stopFadeTimer()
    }

    func fadeOutAndStop(duration: Double) {
        guard let player = audioPlayer, player.isPlaying else { return }
        stopFadeTimer()

        let startVolume = player.volume
        if startVolume <= 0.001 {
            stop()
            return
        }

        let stepInterval = 0.05
        let steps = max(1, Int(duration / stepInterval))
        var step = 0

        fadeTimer = .scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            guard let self, let active = self.audioPlayer else {
                timer.invalidate()
                return
            }
            step += 1
            let progress = min(Double(step) / Double(steps), 1)
            active.volume = max(0, startVolume * Float(1 - progress))

            if progress >= 1 {
                timer.invalidate()
                self.stopFadeTimer()
                self.stop()
            }
        }
    }

    func resume() {
        _ = audioPlayer?.play()
    }

    func currentPlaybackTime() -> Double {
        audioPlayer?.currentTime ?? 0
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onTrackFinished?()
    }

    private func startTimer() {
        timer = .scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, let player = self.audioPlayer else { return }
            player.updateMeters()
            let power = player.averagePower(forChannel: 0)
            let normalized = Double(min(max((power + 60) / 60, 0), 1))
            self.onTimeUpdate?(player.currentTime, max(player.duration, 1))
            self.onAudioEnergy?(normalized)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func stopFadeTimer() {
        fadeTimer?.invalidate()
        fadeTimer = nil
    }

    deinit {
        stopTimer()
        stopFadeTimer()
    }
}
