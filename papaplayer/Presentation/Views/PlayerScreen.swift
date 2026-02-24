import SwiftUI
import UniformTypeIdentifiers

struct PlayerScreen: View {
    @ObservedObject var viewModel: PlayerViewModel

    @State private var showingImporter = false
    @State private var searchText = ""
    @State private var miniPlayerMode = false
    @State private var isDropTargeted = false

    private var primaryThemeColor: Color {
        viewModel.appColorMode == .yellow ? .yellow : .blue
    }

    private var accentThemeColor: Color {
        viewModel.appColorMode == .yellow ? .orange : .cyan
    }

    var body: some View {
        ZStack {
            BubblyBackgroundView(colorMode: viewModel.appColorMode)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 14) {
                    header

                    if miniPlayerMode {
                        miniPlayerCard
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        nowPlayingCard
                            .transition(.move(edge: .top).combined(with: .opacity))

                        if viewModel.gameModeEnabled {
                            rhythmGameCard
                                .transition(.opacity.combined(with: .scale))
                        }

                        controlsCard

                        playlistCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if isDropTargeted {
                        dropHint
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: 1120)
                .frame(maxWidth: .infinity)
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: miniPlayerMode)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.audio, .mpeg4Audio, .mp3, .wav],
            allowsMultipleSelection: true
        ) { result in
            if case let .success(urls) = result {
                viewModel.importTracks(from: urls)
            }
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            viewModel.importFromProviders(providers)
            return true
        }
        .overlay(alignment: .bottomTrailing) {
            keyboardShortcutsLayer
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bubble Player")
                    .font(.system(size: 31, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Local tracks. Bubble vibes. Party game mode.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.6))
                    .lineLimit(1)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    wideHeaderButton(
                        title: miniPlayerMode ? "Full" : "Mini",
                        system: miniPlayerMode ? "rectangle.expand.vertical" : "rectangle.compress.vertical"
                    ) {
                        withAnimation {
                            miniPlayerMode.toggle()
                        }
                    }

                    wideHeaderButton(
                        title: "Game",
                        system: viewModel.gameModeEnabled ? "gamecontroller.fill" : "gamecontroller"
                    ) {
                        withAnimation {
                            viewModel.toggleGameMode()
                        }
                    }

                    wideHeaderButton(title: "Add Music", system: "plus.circle.fill") {
                        showingImporter = true
                    }
                }

                HStack(spacing: 8) {
                    iconHeaderButton(system: miniPlayerMode ? "rectangle.expand.vertical" : "rectangle.compress.vertical") {
                        withAnimation {
                            miniPlayerMode.toggle()
                        }
                    }
                    iconHeaderButton(system: viewModel.gameModeEnabled ? "gamecontroller.fill" : "gamecontroller") {
                        withAnimation {
                            viewModel.toggleGameMode()
                        }
                    }
                    iconHeaderButton(system: "plus.circle.fill") {
                        showingImporter = true
                    }
                }
            }

            Picker("Theme", selection: $viewModel.appColorMode) {
                ForEach(GameColorMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: 980, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func wideHeaderButton(title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(.white.opacity(0.55), in: Capsule())
                .foregroundStyle(.black.opacity(0.82))
        }
        .buttonStyle(.plain)
    }

    private func iconHeaderButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.55), in: Circle())
                .foregroundStyle(.black.opacity(0.82))
        }
        .buttonStyle(.plain)
    }

    private var miniPlayerCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ArtworkView(track: viewModel.currentTrack, size: 64, colorMode: viewModel.appColorMode)

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.currentTrack?.title ?? "No Track")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.82))
                        .lineLimit(1)

                    Text(viewModel.currentTrack?.artist ?? "Local music")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.58))
                        .lineLimit(1)
                }

                Spacer()

                if viewModel.gameModeEnabled {
                    Text("GAME")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentThemeColor.opacity(0.85), in: Capsule())
                        .foregroundStyle(.white)
                }

                HStack(spacing: 12) {
                    iconButton(system: "backward.end.fill", size: 20, action: viewModel.previous)
                    iconButton(system: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill", size: 32, action: viewModel.playPause)
                    iconButton(system: "forward.end.fill", size: 20, action: viewModel.next)
                }
            }

            Slider(value: $viewModel.currentTime, in: 0...max(viewModel.duration, 1), onEditingChanged: { editing in
                if !editing {
                    viewModel.seek(to: viewModel.currentTime)
                }
            })
            .tint(accentThemeColor.opacity(0.95))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(primaryThemeColor.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.7), lineWidth: 1)
                )
        )
    }

    private var nowPlayingCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(primaryThemeColor.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.65), lineWidth: 1.2)
                )

            VStack(spacing: 14) {
                ZStack {
                    ArtworkView(track: viewModel.currentTrack, size: 140, colorMode: viewModel.appColorMode)
                        .shadow(color: accentThemeColor.opacity(0.4), radius: 18, y: 10)
                        .scaleEffect(viewModel.isPlaying ? 1.03 : 1.0)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: viewModel.isPlaying)

                    if viewModel.isPlaying {
                        EqualizerView()
                            .frame(width: 156, height: 156)
                    }
                }

                Text(viewModel.currentTrack?.title ?? "Pick some MP3 files to start")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
                    .lineLimit(1)

                Text(viewModel.currentTrack?.artist ?? "Local music")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.55))
                    .lineLimit(1)

                if let album = viewModel.currentTrack?.album, !album.isEmpty {
                    Text(album)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.48))
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
    }

    private var controlsCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Slider(value: $viewModel.currentTime, in: 0...max(viewModel.duration, 1), onEditingChanged: { editing in
                    if !editing {
                        viewModel.seek(to: viewModel.currentTime)
                    }
                })
                .tint(accentThemeColor.opacity(0.9))

                HStack {
                    Text(viewModel.formattedTime(viewModel.currentTime))
                    Spacer()
                    Text(viewModel.formattedTime(viewModel.duration))
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.6))
            }

            HStack(spacing: 18) {
                iconButton(system: viewModel.shuffleEnabled ? "shuffle.circle.fill" : "shuffle.circle") {
                    viewModel.shuffleEnabled.toggle()
                }
                iconButton(system: "backward.end.fill", size: 23, action: viewModel.previous)

                Button(action: viewModel.playPause) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.black.opacity(0.82))
                        .shadow(color: primaryThemeColor.opacity(0.8), radius: 10, y: 4)
                }
                .buttonStyle(.plain)

                iconButton(system: "forward.end.fill", size: 23, action: viewModel.next)

                iconButton(system: viewModel.repeatMode.symbolName, action: viewModel.cycleRepeatMode)

                iconButton(system: viewModel.currentTrack?.isFavorite == true ? "heart.fill" : "heart", action: viewModel.toggleCurrentFavorite)
            }

            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                Slider(value: $viewModel.volume, in: 0...1)
                    .tint(.black.opacity(0.65))
                Image(systemName: "speaker.wave.3.fill")
            }
            .foregroundStyle(.black.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.7), lineWidth: 1)
                )
        )
    }

    private var playlistCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Library")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.8))

                Spacer()

                Text("\(viewModel.filteredTracks(searchText).count) tracks")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.55))
            }

            Picker("Filter", selection: $viewModel.libraryFilter) {
                ForEach(LibraryFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.black.opacity(0.5))
                TextField("Search songs, artists, albums...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(.white.opacity(0.55), in: Capsule())

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredTracks(searchText)) { track in
                        Button {
                            viewModel.play(track: track)
                        } label: {
                            HStack(spacing: 12) {
                                ArtworkView(track: track, size: 40, colorMode: viewModel.appColorMode)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(.black.opacity(0.8))
                                        .lineLimit(1)

                                    Text(track.artist)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(.black.opacity(0.5))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(track.playCount > 0 ? "\(track.playCount)x" : "")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.black.opacity(0.4))

                                Button {
                                    viewModel.toggleFavorite(track)
                                } label: {
                                    Image(systemName: track.isFavorite ? "heart.fill" : "heart")
                                        .foregroundStyle(track.isFavorite ? accentThemeColor : .black.opacity(0.45))
                                }
                                .buttonStyle(.plain)

                                if viewModel.currentTrack?.id == track.id, viewModel.isPlaying {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundStyle(accentThemeColor)
                                        .transition(.opacity.combined(with: .scale))
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.white.opacity(viewModel.currentTrack?.id == track.id ? 0.75 : 0.55))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 250)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(primaryThemeColor.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.65), lineWidth: 1)
                )
        )
    }

    private var dropHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.down.fill")
            Text("Drop audio files or folders to import")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.72), in: Capsule())
        .foregroundStyle(.black.opacity(0.8))
    }

    private var keyboardShortcutsLayer: some View {
        Group {
            Button("PlayPause", action: viewModel.playPause)
                .keyboardShortcut(.space, modifiers: [])

            Button("Next", action: viewModel.next)
                .keyboardShortcut(.rightArrow, modifiers: [])

            Button("Previous", action: viewModel.previous)
                .keyboardShortcut(.leftArrow, modifiers: [])

            Button("ToggleFavorite", action: viewModel.toggleCurrentFavorite)
                .keyboardShortcut("f", modifiers: [.command])

            Button("LaneA") { viewModel.hitNearestNote(in: 0) }
                .keyboardShortcut("a", modifiers: [])

            Button("LaneS") { viewModel.hitNearestNote(in: 1) }
                .keyboardShortcut("s", modifiers: [])

            Button("LaneD") { viewModel.hitNearestNote(in: 2) }
                .keyboardShortcut("d", modifiers: [])

            Button("LaneF") { viewModel.hitNearestNote(in: 3) }
                .keyboardShortcut("f", modifiers: [])
        }
        .labelsHidden()
        .frame(width: 1, height: 1)
        .opacity(0.01)
    }

    private var rhythmGameCard: some View {
        VStack(spacing: 8) {
            Button {
                viewModel.restartGameRound()
            } label: {
                Label("Restart party round", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.62), in: Capsule())
                    .foregroundStyle(.black.opacity(0.82))
            }
            .buttonStyle(.plain)

            RhythmGameView(
                notes: viewModel.rhythmNotes,
                splashes: viewModel.honeySplashes,
                ripples: viewModel.honeyRipples,
                callouts: viewModel.partyCallouts,
                currentTime: viewModel.currentTime,
                score: viewModel.gameScore,
                combo: viewModel.gameCombo,
                highCombo: viewModel.gameHighCombo,
                misses: viewModel.gameMisses,
                fillLevel: viewModel.bubbleDangerFill,
                isLost: viewModel.gameLost,
                laneCount: viewModel.rhythmLaneCount,
                hitZoneRatio: viewModel.rhythmTargetZoneRatio,
                colorMode: viewModel.appColorMode
            ) { noteID in
                viewModel.hitNote(noteID)
            }
        }
    }

    private func iconButton(system: String, size: CGFloat = 26, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: size))
                .foregroundStyle(.black.opacity(0.82))
        }
        .buttonStyle(.plain)
    }
}
