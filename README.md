# Bubble Player

Bubble Player is a macOS local music player built with SwiftUI, with an arcade-style bubble game mode layered on top of playback.

## Highlights

- Local audio import from files or folders
- Drag-and-drop import support
- Metadata-aware library (title, artist, album, artwork when available)
- Playback controls: play/pause, next/previous, seek, volume
- Shuffle and repeat modes
- Library filters: All, Favorites, Recent, Top
- Favorites + play count tracking
- Theme switcher: Yellow / Blue
- Mini player mode
- Rhythm game mode with animated falling bubbles, water fill physics, score/combo, and party callouts
- Smooth game-over audio fade-out (no abrupt hard stop)

## Game Mode

Toggle **Game** from the header to enable the rhythm game.

Rules:

- Bubbles fall in 4 lanes while your track plays.
- Pop bubbles before they reach the bottom.
- Missed bubbles raise the water level.
- If water reaches max, the party ends and music fades out.

In-game UI:

- Score, combo, best combo, misses
- Floating party warning callouts as pressure rises
- **Restart party round** button to restart immediately

## Keyboard Shortcuts

- `Space`: Play/Pause
- `Right Arrow`: Next track
- `Left Arrow`: Previous track
- `Cmd + F`: Toggle favorite on current track
- `A`, `S`, `D`, `F`: Hit nearest bubble in lanes 1-4 (game mode)

## Supported Audio

The importer accepts any file type that conforms to `UTType.audio`.
Common tested types in the UI import picker include:

- MP3 (`.mp3`)
- WAV (`.wav`)
- MPEG-4 Audio (`.m4a` and related)

## Build & Run

### Requirements

- Xcode (with SwiftUI + macOS SDK support)
- macOS development environment

### Open in Xcode

1. Open `/Users/prabhatsingh/Documents/papaplayer/papaplayer.xcodeproj`
2. Select scheme: `papaplayer`
3. Build and run

### CLI Build

```bash
cd /Users/prabhatsingh/Documents/papaplayer
xcodebuild -project papaplayer.xcodeproj -scheme papaplayer -destination 'platform=macOS,arch=arm64' -derivedDataPath ./DerivedData build
```

## Project Structure

```text
papaplayer/
  Domain/
    Enums/
    Models/
  Infrastructure/
    Services/
  Presentation/
    Components/
    ViewModels/
    Views/
```

- `Domain`: core models/enums (`Track`, `RhythmNote`, filters, repeat mode, theme mode)
- `Infrastructure/Services`:
  - `TrackImportService`: import, directory expansion, metadata extraction, persistent file copy
  - `AudioPlaybackService`: AVAudioPlayer wrapper, metering, progress callbacks, fade-out stop
- `Presentation/ViewModels`:
  - `PlayerViewModel`: app state, playback actions, filtering, game mechanics
- `Presentation/Views` + `Components`:
  - `PlayerScreen`, `RhythmGameView`, animated UI building blocks

## Notes

- App display name is configured as **Bubble Player**.
- Some internal model names still use `Honey*` identifiers from earlier iterations, but visuals/behavior are water-themed in the current game design.

