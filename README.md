# Bubble Player

Bubble Player is a macOS local music player built with SwiftUI, with an arcade-style bubble game mode layered on top of playback.

<img width="1440" height="900" alt="Image" src="https://github.com/user-attachments/assets/e0391358-94da-40c4-85a2-257aabefd639" />

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

<img width="1440" height="900" alt="Image" src="https://github.com/user-attachments/assets/acf6f730-b4f8-4dda-a4e0-fcee78b4862e" />
<img width="1440" height="900" alt="Image" src="https://github.com/user-attachments/assets/c87e6c5d-33a9-46c6-81a2-698716804bb6" />

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
