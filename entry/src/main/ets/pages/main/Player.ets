import router from '@ohos.router'
import { LyricsCard } from '../../components/LyricsCard'
import { SheetHandle } from '../../components/SheetHandle'
import { DEFAULT_TRACK, MUSIC_TRACKS, Track } from '../../model/MusicData'
import { PlayerManager } from '../../model/PlayerManager'
import { AudioEngine } from '../../model/AudioEngine'
import { MeowColors, MeowPlayer, MeowRadius, MeowSpacing, MeowTypography } from '../../theme/theme'
import pasteboard from '@ohos.pasteboard'
import promptAction from '@ohos.promptAction'

interface LyricLine {
  index: number
  text: string
}

@Entry
@Component
struct Player {
  @StorageLink('currentTrack') @Watch('onCurrentTrackChanged') currentTrack: Track = DEFAULT_TRACK
  @StorageLink('isPlaying') @Watch('onPlayingChanged') isPlaying: boolean = false
  @StorageLink('likedTrackIds') likedTrackIds: string = ''
  @StorageLink('followedArtistIds') private followedArtistIds: string = ''
  @StorageLink('currentTimeSeconds') elapsedSeconds: number = 0
  @State private lyricsExpanded: boolean = false
  @State private showConnectSheet: boolean = false
  @State private showShareSheet: boolean = false
  @State private showQueueSheet: boolean = false
  @StorageLink('shuffleEnabled') private shuffleEnabled: boolean = false
  @StorageLink('repeatEnabled') private repeatEnabled: number = 0
  @State private showMenuSheet: boolean = false
  @State private shareCardColorIndex: number = 0
  @State private isDragging: boolean = false
  @State private dragPosition: number = 0
  @State private progressBarWidth: number = 0
  @State private playPressed: boolean = false
  @State private prevPressed: boolean = false
  @State private nextPressed: boolean = false
  @State private shufflePressed: boolean = false
  @State private repeatPressed: boolean = false
  @State private cachedLyrics: LyricLine[] = []
  // Album artwork slide transition state (driven by animateTo on track change).
  @State private coverShift: number = 0
  @State private coverFade: number = 1
  @State private coverScaleV: number = 1
  private isCoverAnimating: boolean = false
  private prevTrackId: string = ''
  private lastTrackChangeMs: number = 0

  aboutToAppear(): void {
    this.elapsedSeconds = Math.max(0, Math.min(this.elapsedSeconds, this.currentTrack.duration))
    this.prevTrackId = this.currentTrack.id
    this.cachedLyrics = this.buildLyrics()
  }

  private onPlayingChanged(): void {
    // Keep the position timer running while playing so Lyrics Preview + progress
    // advance; stop it when paused so they hold at the current line.
    if (this.isPlaying) {
      AudioEngine.startTracking()
    } else {
      AudioEngine.stopTracking()
    }
  }

  private onCurrentTrackChanged(): void {
    if (this.currentTrack.id !== this.prevTrackId) {
      this.lyricsExpanded = false
      this.shareCardColorIndex = 0
      this.prevTrackId = this.currentTrack.id
      this.cachedLyrics = this.buildLyrics()
    }
  }

  private activeLyricIndexFor(seconds: number): number {
    if (this.currentTrack.lyrics.length === 0 || this.currentTrack.timestamps.length === 0) {
      return -1
    }
    let tsIndex = 0
    const elapsedMs = seconds * 1000
    for (let i = 0; i < this.currentTrack.timestamps.length; i++) {
      if (elapsedMs >= this.currentTrack.timestamps[i]) {
        tsIndex = i
      }
    }
    // Timestamps are authored for sung lines only, while the lyrics array also
    // holds blank spacer lines. Map the tsIndex-th timestamp to the tsIndex-th
    // non-blank lyric so highlighting stays aligned when blanks are interleaved.
    return this.lyricIndexForTimestamp(tsIndex)
  }

  private lyricIndexForTimestamp(tsIndex: number): number {
    const lyrics = this.currentTrack.lyrics
    let nonBlankSeen = -1
    for (let i = 0; i < lyrics.length; i++) {
      if (lyrics[i].trim().length > 0) {
        nonBlankSeen++
        if (nonBlankSeen === tsIndex) {
          return i
        }
      }
    }
    return Math.min(tsIndex, lyrics.length - 1)
  }

  private resetPlaybackPosition(): void {
    this.elapsedSeconds = 0
  }

  private activeLyricIndex(): number {
    const secs = this.isDragging ? this.dragPosition : this.elapsedSeconds
    return this.activeLyricIndexFor(secs)
  }

  private buildLyrics(): LyricLine[] {
    const lines: LyricLine[] = []
    for (let i = 0; i < this.currentTrack.lyrics.length; i++) {
      lines.push({ index: i, text: this.currentTrack.lyrics[i] })
    }
    return lines
  }

  private allLyrics(): LyricLine[] {
    return this.cachedLyrics
  }

  private progressPercent(): string {
    if (this.currentTrack.duration <= 0) {
      return '0%'
    }
    const secs = this.isDragging ? this.dragPosition : this.elapsedSeconds
    return `${Math.min(100, Math.max(0, Math.floor((secs / this.currentTrack.duration) * 100)))}%`
  }

  private elapsedLabel(): string {
    const secs = this.isDragging ? this.dragPosition : this.elapsedSeconds
    const minutes = Math.floor(secs / 60)
    const seconds = Math.floor(secs) % 60
    return `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`
  }

  private togglePlay(): void {
    PlayerManager.togglePlay(this.isPlaying)
    console.log(`[PlayerPage] toggle ${this.currentTrack.title}`)
  }

  // Slide the album artwork when the track changes: the current cover slides
  // out (next → left, previous → right) while fading/shrinking; the track is
  // swapped while the cover is invisible; then the new cover drops onto the
  // opposite side and slides into centre. dir = +1 for next, -1 for previous.
  // While a slide is running (or within the debounce window) further taps are
  // ignored, so rapid Next/Previous can never desync cover/title/lyrics.
  private animatedTrackChange(dir: number, applyChange: () => void): void {
    const now = Date.now()
    if (this.isCoverAnimating || now - this.lastTrackChangeMs < 220) {
      return
    }
    this.lastTrackChangeMs = now
    this.isCoverAnimating = true
    const dist = 44
    // Phase 1 — current cover slides out + fades + shrinks.
    animateTo({ duration: 130, curve: Curve.EaseIn, onFinish: () => {
      applyChange()
      this.resetPlaybackPosition()
      this.lyricsExpanded = false
      // Drop the (now swapped) cover on the opposite side, invisibly.
      animateTo({ duration: 0 }, () => {
        this.coverShift = dir * dist
      })
      // Phase 2 — new cover slides in to centre + fades + grows.
      animateTo({ duration: 210, curve: Curve.EaseOut, onFinish: () => {
        this.isCoverAnimating = false
      } }, () => {
        this.coverShift = 0
        this.coverFade = 1
        this.coverScaleV = 1
      })
    } }, () => {
      this.coverShift = -dir * dist
      this.coverFade = 0
      this.coverScaleV = 0.96
    })
  }

  private previousTrack(): void {
    this.animatedTrackChange(-1, () => {
      this.shuffleEnabled = false
      this.repeatEnabled = 0
      PlayerManager.playPrevious(this.currentTrack, this.isPlaying)
      console.log('[PlayerPage] previous track')
    })
  }

  private nextTrack(): void {
    this.animatedTrackChange(1, () => {
      if (this.shuffleEnabled) {
        const next = PlayerManager.shuffledNextTrack(this.currentTrack)
        this.shuffleEnabled = false
        this.repeatEnabled = 0
        PlayerManager.setCurrentTrack(next, this.isPlaying)
      } else {
        this.shuffleEnabled = false
        this.repeatEnabled = 0
        PlayerManager.playNext(this.currentTrack, this.isPlaying)
      }
      console.log('[PlayerPage] next track')
    })
  }

  private toggleLike(): void {
    PlayerManager.toggleLikedInStorage(this.currentTrack, this.likedTrackIds)
    console.log(`[PlayerPage] add to library ${this.currentTrack.title}`)
  }

  private toggleShuffle(): void {
    this.shuffleEnabled = !this.shuffleEnabled
    console.log(`[PlayerPage] shuffle ${this.shuffleEnabled}`)
  }

  private toggleRepeat(): void {
    this.repeatEnabled = (this.repeatEnabled + 1) % 3
    console.log(`[PlayerPage] repeat ${this.repeatEnabled}`)
  }

  private currentTrackLiked(): boolean {
    return PlayerManager.isLiked(this.currentTrack, this.likedTrackIds)
  }

  private async openArtistSongs(): Promise<void> {
    console.log(`[PlayerPage] explore artist ${this.currentTrack.artist}`)
    await router.pushUrl({ url: 'pages/main/ArtistSongs' })
  }

  private closePlayer(): void {
    console.log('[PlayerPage] close player')
    router.back()
  }

  private shareCardBg(): ResourceColor {
    if (this.shareCardColorIndex === 0) { return this.currentTrack.accent }
    if (this.shareCardColorIndex === 1) { return MeowColors.navyButtonStart }
    if (this.shareCardColorIndex === 2) { return MeowColors.solidSurface }
    return MeowColors.navyDeep
  }

  private artistTracks(): Track[] {
    return MUSIC_TRACKS.filter((t: Track): boolean => t.artist === this.currentTrack.artist)
  }

  private openSystemShare(): void {
    promptAction.showToast({ message: 'Share: Coming soon', duration: 2000 })
  }

  private dismissSheets(): void {
    this.showConnectSheet = false
    this.showShareSheet = false
    this.showQueueSheet = false
    this.showMenuSheet = false
  }

  private upcomingTracks(): Track[] {
    const idx = MUSIC_TRACKS.findIndex((t: Track): boolean => t.id === this.currentTrack.id)
    const result: Track[] = []
    const start = idx >= 0 ? idx : 0
    for (let i = 1; i <= 6; i++) {
      result.push(MUSIC_TRACKS[(start + i) % MUSIC_TRACKS.length])
    }
    return result
  }

  @Builder
  private TopIcon(label: string, action: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Text(label)
        .fontSize(label === '⋮' ? 24 : 28)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .textAlign(TextAlign.Center)
        .hitTestBehavior(HitTestMode.None)
    }
    .width(44)
    .height(44)
    .borderRadius(22)
    .backgroundColor(MeowColors.glassBgSoft)
    .border({ width: 1, color: MeowColors.borderSubtle })
    .hitTestBehavior(HitTestMode.Block)
    .onClick(action)
  }

  @Builder
  private TopBar() {
    Row() {
      this.TopIcon('<', () => {
        this.closePlayer()
      })
      Column({ space: 2 }) {
        Text(`Playing from ${this.currentTrack.artist}`)
          .fontSize(MeowTypography.captionSize)
          .fontWeight(FontWeight.Regular)
          .fontColor(MeowColors.textTertiary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.currentTrack.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      this.TopIcon('⋮', () => {
        this.showMenuSheet = true
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private CoverStage() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width('100%')
          .aspectRatio(1)
          .borderRadius(MeowRadius.large)
          .backgroundColor(MeowColors.glassBgSoft)
          .border({ width: 1, color: 'rgba(255,255,255,0.08)' })

      Image(this.currentTrack.artwork)
        .width('100%')
        .aspectRatio(1)
        .objectFit(ImageFit.Cover)
        .borderRadius(MeowRadius.large)
        .clip(true)
        .translate({ x: this.coverShift })
        .scale({ x: this.coverScaleV, y: this.coverScaleV })
        .opacity(this.coverFade)
      }
      .width(MeowPlayer.albumWidthPercent)
      .constraintSize({ minWidth: MeowPlayer.albumMinWidth, maxWidth: MeowPlayer.albumMaxWidth })
      .aspectRatio(1)
      .borderRadius(MeowRadius.large)
      .shadow({
        radius: 28,
        color: this.currentTrack.accentSoft,
        offsetX: 0,
        offsetY: 10
      })
      .scale({
        x: this.isPlaying ? MeowPlayer.albumPlayingScale : MeowPlayer.albumPausedScale,
        y: this.isPlaying ? MeowPlayer.albumPlayingScale : MeowPlayer.albumPausedScale
      })
      .animation({ duration: MeowPlayer.albumZoomDuration, curve: Curve.EaseOut })
      .parallelGesture(
        PanGesture({ direction: PanDirection.Horizontal, distance: 44 })
          .onActionEnd((event: GestureEvent) => {
            if (event.offsetX <= -48) {
              this.nextTrack()
            } else if (event.offsetX >= 48) {
              this.previousTrack()
            }
          })
      )
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private AddLibraryIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(MeowPlayer.addButtonSize - 4)
        .height(MeowPlayer.addButtonSize - 4)
        .fill(this.currentTrackLiked() ? this.currentTrack.accentSoft : 'rgba(255,255,255,0.04)')
        .stroke(this.currentTrackLiked() ? this.currentTrack.accent : 'rgba(255,255,255,0.55)')
        .strokeWidth(1)
        .hitTestBehavior(HitTestMode.None)
      Text(this.currentTrackLiked() ? '✓' : '+')
        .fontSize(MeowPlayer.addIconSize)
        .fontWeight(this.currentTrackLiked() ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTrackLiked() ? this.currentTrack.accent : MeowColors.textPrimary)
        .textAlign(TextAlign.Center)
        .hitTestBehavior(HitTestMode.None)
    }
    .width(MeowPlayer.addButtonSize)
    .height(MeowPlayer.addButtonSize)
    .hitTestBehavior(HitTestMode.Block)
    .onClick(() => {
      this.toggleLike()
    })
  }

  @Builder
  private SongInfoRow() {
    Row({ space: 14 }) {
      Column({ space: 5 }) {
        Text(this.currentTrack.title)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.currentTrack.artist)
          .fontSize(15)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      this.AddLibraryIcon()
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ right: 8 })
  }

  @Builder
  private Progress() {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width('100%')
          .height(4)
          .borderRadius(2)
          .backgroundColor('rgba(255,255,255,0.25)')
        Row() {
          Row()
            .width(this.progressPercent())
            .height(4)
            .borderRadius(2)
            .backgroundColor(this.currentTrack.accent)
          Blank()
        }
        .width('100%')
        .height(4)
        Row() {
          Row()
            .width(this.progressPercent())
            .height(14)
          Circle()
            .width(14)
            .height(14)
            .fill(this.currentTrack.accent)
            .shadow({ radius: 6, color: this.currentTrack.accent, offsetX: 0, offsetY: 0 })
            .translate({ x: -7 })
          Blank()
        }
        .width('100%')
        .height(14)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(44)
      .onAreaChange((_old: Area, newArea: Area) => {
        this.progressBarWidth = newArea.width as number
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          AudioEngine.stopTracking()
          this.isDragging = true
          if (event.touches.length > 0 && this.currentTrack.duration > 0) {
            const width = this.progressBarWidth
            if (width > 0) {
              const fraction = Math.max(0, Math.min(1, event.touches[0].x / width))
              this.dragPosition = Math.floor(fraction * this.currentTrack.duration)
              this.elapsedSeconds = this.dragPosition
            }
          }
          return
        }
        if (event.type === TouchType.Move &&
          event.touches.length > 0 && this.currentTrack.duration > 0) {
          const width = this.progressBarWidth
          if (width > 0) {
            const fraction = Math.max(0, Math.min(1, event.touches[0].x / width))
            this.dragPosition = Math.floor(fraction * this.currentTrack.duration)
            this.elapsedSeconds = this.dragPosition
          }
          return
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          if (event.type === TouchType.Up) {
            this.elapsedSeconds = this.dragPosition
            AudioEngine.seekTo(this.dragPosition)
          } else {
            AudioEngine.startTracking()
          }
          this.isDragging = false
        }
      })

      Row() {
        Text(this.elapsedLabel())
          .fontSize(11)
          .fontColor(MeowColors.textSecondary)
        Blank()
        Text(this.currentTrack.durationLabel)
          .fontSize(11)
          .fontColor(MeowColors.textSecondary)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private ControlIcon(label: string, active: boolean, action: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Text(label)
        .fontSize(25)
        .fontWeight(FontWeight.Bold)
        .fontColor(active ? this.currentTrack.accent : MeowColors.textSecondary)
        .textAlign(TextAlign.Center)
        .opacity(active ? 1 : 0.84)
        .hitTestBehavior(HitTestMode.None)
    }
    .width(46)
    .height(46)
    .hitTestBehavior(HitTestMode.Block)
    .onClick(action)
  }

  @Builder
  private PlayPauseButton() {
    // Primary — solid white circle with a dark glyph centred inside. The opaque
    // circle is the tap target; a subtle circular shadow keeps it premium (no
    // square/rectangular background).
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(MeowPlayer.playTap)
        .height(MeowPlayer.playTap)
        .fill(MeowColors.textPrimary)
        .hitTestBehavior(HitTestMode.None)
        .shadow(this.playPressed
          ? { radius: 16, color: this.currentTrack.accent, offsetX: 0, offsetY: 0 }
          : { radius: 10, color: 'rgba(0,0,0,0.28)', offsetX: 0, offsetY: 4 })
      if (this.isPlaying) {
        // Pause — system symbol (correct proportions, no taper / no padding).
        SymbolGlyph($r('sys.symbol.pause_fill'))
          .fontSize(MeowPlayer.pauseIcon)
          .fontColor([MeowColors.navyDeep])
          .hitTestBehavior(HitTestMode.None)
      } else {
        // Play — system symbol (correct proportions, no taper / no padding).
        SymbolGlyph($r('sys.symbol.play_fill'))
          .fontSize(MeowPlayer.playIcon)
          .fontColor([MeowColors.navyDeep])
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width(MeowPlayer.playTap)
    .height(MeowPlayer.playTap)
    .scale({ x: this.playPressed ? 0.93 : 1, y: this.playPressed ? 0.93 : 1 })
    .animation({ duration: 130, curve: Curve.EaseOut })
    .focusable(false)
    .hitTestBehavior(HitTestMode.Block)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.playPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.playPressed = false
      }
    })
    .onClick(() => {
      this.togglePlay()
    })
  }

  @Builder
  private Controls() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Column({ space: 3 }) {
          Path()
            .width(MeowPlayer.sideIcon)
            .height(MeowPlayer.sideIcon)
            .commands('M22.2 17.4 L4.8 0 L0 4.8 L17.4 22.2 L22.2 17.4 Z M35.4 0 L42.3 6.9 L0 49.2 L4.8 54 L47.1 11.7 L54 18.6 L54 0 L35.4 0 Z M36.6 31.5 L31.8 36.3 L42.4 46.8 L35.4 54 L54 54 L54 35.4 L47.1 42.3 L36.6 31.8 L36.6 31.5 Z')
            .fill(this.shuffleEnabled ? this.currentTrack.accent : 'rgba(255,255,255,0.88)')
            .stroke(MeowColors.transparent)
            .hitTestBehavior(HitTestMode.None)
          Row()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(this.shuffleEnabled ? this.currentTrack.accent : MeowColors.transparent)
            .hitTestBehavior(HitTestMode.None)
        }
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.None)
      }
      .width(MeowPlayer.sideTap)
      .height(MeowPlayer.sideTap)
      .scale({ x: this.shufflePressed ? 0.94 : 1, y: this.shufflePressed ? 0.94 : 1 })
      .animation({ duration: 130, curve: Curve.EaseOut })
      .hitTestBehavior(HitTestMode.Block)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.shufflePressed = true
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.shufflePressed = false
        }
      })
      .onClick(() => { this.toggleShuffle() })

      Stack({ alignContent: Alignment.Center }) {
        Path()
          .width(MeowPlayer.skipIcon)
          .height(MeowPlayer.skipIcon)
          .commands('M0 0 L9.7 0 L9.7 58 L0 58 L0 0 Z M16.9 29 L58 58 L58 0 L16.9 29 Z')
          .fill('rgba(255,255,255,0.95)')
          .stroke(MeowColors.transparent)
          .hitTestBehavior(HitTestMode.None)
      }
      .width(MeowPlayer.skipTap)
      .height(MeowPlayer.skipTap)
      .scale({ x: this.prevPressed ? 0.94 : 1, y: this.prevPressed ? 0.94 : 1 })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .hitTestBehavior(HitTestMode.Block)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.prevPressed = true
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.prevPressed = false
        }
      })
      .onClick(() => { this.previousTrack() })

      this.PlayPauseButton()

      Stack({ alignContent: Alignment.Center }) {
        Path()
          .width(MeowPlayer.skipIcon)
          .height(MeowPlayer.skipIcon)
          .commands('M0 58 L41.1 29 L0 0 L0 58 Z M48.3 0 L48.3 58 L58 58 L58 0 L48.3 0 Z')
          .fill('rgba(255,255,255,0.95)')
          .stroke(MeowColors.transparent)
          .hitTestBehavior(HitTestMode.None)
      }
      .width(MeowPlayer.skipTap)
      .height(MeowPlayer.skipTap)
      .scale({ x: this.nextPressed ? 0.94 : 1, y: this.nextPressed ? 0.94 : 1 })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .hitTestBehavior(HitTestMode.Block)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.nextPressed = true
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.nextPressed = false
        }
      })
      .onClick(() => { this.nextTrack() })

      Stack({ alignContent: Alignment.Center }) {
        Column({ space: 2 }) {
          Path()
            .width(MeowPlayer.sideIcon)
            .height(MeowPlayer.sideIcon)
            .commands('M13.5 13.5 L40.5 13.5 L40.5 21.6 L51.3 10.8 L40.5 0 L40.5 8.1 L8.1 8.1 L8.1 24.3 L13.5 24.3 L13.5 13.5 Z M40.5 40.5 L13.5 40.5 L13.5 32.4 L2.7 43.2 L13.5 54 L13.5 45.9 L45.9 45.9 L45.9 29.7 L40.5 29.7 L40.5 40.5 Z')
            .fill(this.repeatEnabled > 0 ? this.currentTrack.accent : 'rgba(255,255,255,0.88)')
            .stroke(MeowColors.transparent)
            .hitTestBehavior(HitTestMode.None)
          if (this.repeatEnabled === 2) {
            Text('1')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentTrack.accent)
              .textAlign(TextAlign.Center)
              .hitTestBehavior(HitTestMode.None)
          } else {
            Row()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(this.repeatEnabled === 1 ? this.currentTrack.accent : MeowColors.transparent)
              .hitTestBehavior(HitTestMode.None)
          }
        }
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.None)
      }
      .width(MeowPlayer.sideTap)
      .height(MeowPlayer.sideTap)
      .scale({ x: this.repeatPressed ? 0.94 : 1, y: this.repeatPressed ? 0.94 : 1 })
      .animation({ duration: 130, curve: Curve.EaseOut })
      .hitTestBehavior(HitTestMode.Block)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.repeatPressed = true
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.repeatPressed = false
        }
      })
      .onClick(() => { this.toggleRepeat() })
    }
    .width('96%')
    .height(84)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  private ShareActionIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(MeowPlayer.secondaryIcon - 5)
        .height(2)
        .borderRadius(1)
        .backgroundColor('rgba(255,255,255,0.88)')
        .rotate({ angle: -32 })
        .translate({ x: 0, y: -2 })
      Row()
        .width(MeowPlayer.secondaryIcon - 5)
        .height(2)
        .borderRadius(1)
        .backgroundColor('rgba(255,255,255,0.88)')
        .rotate({ angle: 28 })
        .translate({ x: 0, y: 5 })
      Circle()
        .width(7)
        .height(7)
        .fill('rgba(255,255,255,0.88)')
        .translate({ x: -9, y: 7 })
      Circle()
        .width(7)
        .height(7)
        .fill('rgba(255,255,255,0.88)')
        .translate({ x: 8, y: -8 })
      Circle()
        .width(7)
        .height(7)
        .fill('rgba(255,255,255,0.88)')
        .translate({ x: 10, y: 9 })
    }
    .width(MeowPlayer.secondaryTap)
    .height(MeowPlayer.secondaryTap)
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  private QueueActionIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(MeowPlayer.secondaryIcon)
        .height(2.4)
        .borderRadius(1.2)
        .backgroundColor('rgba(255,255,255,0.88)')
        .translate({ x: 0, y: -7 })
      Row()
        .width(MeowPlayer.secondaryIcon)
        .height(2.4)
        .borderRadius(1.2)
        .backgroundColor('rgba(255,255,255,0.88)')
      Row()
        .width(MeowPlayer.secondaryIcon)
        .height(2.4)
        .borderRadius(1.2)
        .backgroundColor('rgba(255,255,255,0.88)')
        .translate({ x: 0, y: 7 })
    }
    .width(MeowPlayer.secondaryTap)
    .height(MeowPlayer.secondaryTap)
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  private BottomAction(label: string, action: () => void) {
    Column() {
      if (label === 'Connect') {
        this.DeviceActionIcon()
      } else if (label === 'Share') {
        this.ShareActionIcon()
      } else {
        this.QueueActionIcon()
      }
    }
    .width(72)
    .height(56)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .scale({ x: 1.0, y: 1.0 })
    .opacity(0.88)
    .onClick(action)
  }

  @Builder
  private BottomActions() {
    Row() {
      this.BottomAction('Connect', () => {
        this.showConnectSheet = true
      })
      this.BottomAction('Share', () => {
        this.showShareSheet = true
      })
      this.BottomAction('Queue', () => {
        this.showQueueSheet = true
      })
    }
    .width('84%')
    .height(62)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  private DeviceActionIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(MeowPlayer.secondaryIcon - 7)
        .height(MeowPlayer.secondaryIcon)
        .borderRadius(4)
        .border({ width: 2, color: 'rgba(255,255,255,0.88)' })
      Row()
        .width(5)
        .height(5)
        .borderRadius(3)
        .backgroundColor('rgba(255,255,255,0.88)')
        .translate({ x: 0, y: 7 })
      Row()
        .width(MeowPlayer.secondaryIcon - 11)
        .height(MeowPlayer.secondaryIcon - 7)
        .borderRadius(3)
        .border({ width: 2, color: 'rgba(255,255,255,0.88)' })
        .translate({ x: -11, y: 4 })
    }
    .width(MeowPlayer.secondaryTap)
    .height(MeowPlayer.secondaryTap)
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  private ExpandedLyrics(activeIndex: number) {
    Column({ space: 16 }) {
      Row() {
        Text('Lyrics')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
        Blank()
        Text('Hide')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTrack.accent)
          .onClick(() => {
            this.lyricsExpanded = false
          })
      }
      .width('100%')

      Column({ space: 13 }) {
        ForEach(this.allLyrics(), (line: LyricLine) => {
          Text(line.text.length > 0 ? line.text : ' ')
            .fontSize(line.index === activeIndex ? 20 : 16)
            .fontWeight(line.index === activeIndex ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(line.index === activeIndex ? MeowColors.textPrimary : MeowColors.textTertiary)
            .width('100%')
            .opacity(line.index === activeIndex ? 1 : 0.56)
      }, (line: LyricLine) => `${this.currentTrack.id}-${line.index}`)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(18)
    .borderRadius(MeowRadius.large)
    .backgroundColor(MeowColors.surfaceOverlay)
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
  }

  @Builder
  private ExploreCard(track: Track) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Image(track.artwork)
        .width(140)
        .height(140)
        .objectFit(ImageFit.Cover)
        .borderRadius(MeowRadius.card)
        .clip(true)
      Row()
        .width(140)
        .height(80)
        .linearGradient({
          angle: 180,
          colors: [
            ['rgba(9,10,28,0)', 0.0],
            ['rgba(9,10,28,0.88)', 1.0]
          ]
        })
      Column({ space: 2 }) {
        Text(track.title)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(track.artist)
          .fontSize(10)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
        .width(140)
        .padding({ left: 10, right: 10, bottom: 10 })
        .alignItems(HorizontalAlign.Start)
    }
    .width(140)
    .height(140)
    .borderRadius(MeowRadius.control)
    .clip(true)
    .border({
      width: track.id === this.currentTrack.id ? 2 : 0,
      color: this.currentTrack.accent
    })
    .shadow({
      radius: track.id === this.currentTrack.id ? 16 : 0,
      color: this.currentTrack.accentSoft,
      offsetX: 0,
      offsetY: 0
    })
    .onClick(() => {
      if (track.id !== this.currentTrack.id) {
        PlayerManager.playTrack(track)
      }
    })
  }

  @Builder
  private ArtistInfoCard() {
    Row({ space: 16 }) {
      Column({ space: 5 }) {
        Text(this.currentTrack.artist)
          .fontSize(MeowTypography.titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.currentTrack.listeners)
          .fontSize(13)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(PlayerManager.isFollowed(this.currentTrack.artist, this.followedArtistIds)
        ? 'Following' : 'Follow')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(PlayerManager.isFollowed(this.currentTrack.artist, this.followedArtistIds)
          ? this.currentTrack.accent : MeowColors.textPrimary)
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .borderRadius(MeowRadius.chipPill)
        .border({
          width: 1,
          color: PlayerManager.isFollowed(this.currentTrack.artist,
            this.followedArtistIds) ? this.currentTrack.accent : 'rgba(255,255,255,0.72)'
        })
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => {
          PlayerManager.toggleFollowedInStorage(this.currentTrack.artist, this.followedArtistIds)
          console.log(`[PlayerPage] follow toggled ${this.currentTrack.artist}`)
        })
    }
    .width('100%')
    .padding(20)
    .borderRadius(MeowRadius.card)
    .backgroundColor(MeowColors.surfaceOverlay)
    .border({ width: 1, color: MeowColors.borderSubtle })
    .shadow({
      radius: 22,
      color: 'rgba(0,0,0,0.22)',
      offsetX: 0,
      offsetY: 8
    })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private ExploreArtist() {
    Column({ space: 14 }) {
      Text(`Explore ${this.currentTrack.artist}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')
      Scroll() {
        Row({ space: 12 }) {
          ForEach(this.artistTracks(), (track: Track) => {
            this.ExploreCard(track)
          }, (track: Track) => `explore-${track.id}`)
        }
        .padding({ right: 24 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private MenuRow(icon: string, label: string, active: boolean, action: () => void) {
    Row({ space: 18 }) {
      Text(icon)
        .fontSize(20)
        .fontColor(active ? this.currentTrack.accent : MeowColors.textSecondary)
        .width(28)
        .textAlign(TextAlign.Center)
        .hitTestBehavior(HitTestMode.None)
      Text(label)
        .fontSize(16)
        .fontColor(active ? this.currentTrack.accent : MeowColors.textPrimary)
        .layoutWeight(1)
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
    .hitTestBehavior(HitTestMode.Block)
    .onClick(() => {
      action()
    })
  }

  @Builder
  private MenuSheet() {
    Column({ space: 0 }) {
      Row() {
        SheetHandle()
      }
      .width('100%')
      .height(26)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Row({ space: 14 }) {
        Image(this.currentTrack.artwork)
          .width(52)
          .height(52)
          .borderRadius(MeowRadius.control)
          .objectFit(ImageFit.Cover)
          .clip(true)
          .backgroundColor(MeowColors.solidSurface)
        Column({ space: 4 }) {
          Text(this.currentTrack.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.currentTrack.artist)
            .fontSize(13)
            .fontColor(MeowColors.textSecondary)
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height(76)
      .padding({ left: 12, right: 12 })
      .borderRadius(MeowRadius.card)
      .backgroundColor(MeowColors.glassBg)
      .border({ width: 1, color: MeowColors.borderSubtle })
      .alignItems(VerticalAlign.Center)

      Row()
        .width('100%')
        .height(1)
        .backgroundColor(MeowColors.borderSubtle)
        .margin({ top: 8, bottom: 4 })

      this.MenuRow('↗', 'Share', false, () => {
        this.dismissSheets()
        this.showShareSheet = true
      })
      this.MenuRow(this.currentTrackLiked() ? '♥' : '♡',
        this.currentTrackLiked() ? 'Remove from Liked Songs' : 'Add to Liked Songs',
        this.currentTrackLiked(), () => {
        this.toggleLike()
      })
      this.MenuRow('≡', 'Go to Queue', false, () => {
        this.dismissSheets()
        this.showQueueSheet = true
      })
      this.MenuRow('⊙', 'Connect to a device', false, () => {
        this.dismissSheets()
        this.showConnectSheet = true
      })
      this.MenuRow('◎', 'Go to Artist', false, () => {
        this.dismissSheets()
        this.openArtistSongs()
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 36 })
    .backgroundColor(MeowColors.solidSurface)
    .borderRadius({ topLeft: MeowRadius.bottomSheet, topRight: MeowRadius.bottomSheet, bottomLeft: 0, bottomRight: 0 })
    .border({ width: 1, color: MeowColors.borderSubtle })
  }

  @Builder
  private ShareButton(icon: string, label: string, action: () => void) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(56)
          .height(56)
          .borderRadius(28)
          .backgroundColor(MeowColors.glassBg)
          .border({ width: 1, color: MeowColors.borderStrong })
          .hitTestBehavior(HitTestMode.None)
        Text(icon)
          .fontSize(22)
          .fontColor(MeowColors.textPrimary)
          .textAlign(TextAlign.Center)
          .hitTestBehavior(HitTestMode.None)
      }
      .width(56)
      .height(56)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        action()
      })
      Text(label)
        .fontSize(11)
        .fontColor(MeowColors.textSecondary)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .hitTestBehavior(HitTestMode.None)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private SheetTitleRow(title: string) {
    Text(title)
      .fontSize(MeowTypography.subheadingSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(MeowColors.textPrimary)
      .width('100%')
  }

  @Builder
  private ConnectSheet() {
    Column({ space: 14 }) {
      Row() {
        SheetHandle()
      }
      .width('100%')
      .height(26)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      this.SheetTitleRow('Connect to a device')

      Row({ space: 12 }) {
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(16)
            .height(24)
            .borderRadius(4)
            .border({ width: 2.5, color: this.currentTrack.accent })
          Row()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(this.currentTrack.accent)
            .translate({ x: 0, y: 9 })
        }
        .width(40)
        .height(40)

        Column({ space: 3 }) {
          Text('This Phone')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTrack.accent)
          Text('Standard quality · Active')
            .fontSize(12)
            .fontColor(MeowColors.textTertiary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(22)
            .height(22)
            .fill(this.currentTrack.accentSoft)
            .stroke(this.currentTrack.accent)
            .strokeWidth(2)
          Circle()
            .width(9)
            .height(9)
            .fill(this.currentTrack.accent)
        }
        .width(32)
        .height(32)
      }
      .width('100%')
      .height(68)
      .padding({ left: 14, right: 14 })
      .borderRadius(MeowRadius.card)
      .backgroundColor(this.currentTrack.accentSoft)
      .border({ width: 1, color: MeowColors.borderStrong })
      .alignItems(VerticalAlign.Center)

      Text('No nearby devices found. Make sure Bluetooth is enabled.')
        .fontSize(13)
        .fontColor(MeowColors.textTertiary)
        .textAlign(TextAlign.Center)
        .width('100%')

      Row({ space: 8 }) {
        Text('⊙')
          .fontSize(18)
          .fontColor(MeowColors.textSecondary)
        Text('Search for Bluetooth devices')
          .fontSize(14)
          .fontColor(MeowColors.textSecondary)
      }
      .width('100%')
      .height(48)
      .borderRadius(MeowRadius.control)
      .border({ width: 1, color: MeowColors.borderStrong })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 36 })
    .backgroundColor(MeowColors.solidSurface)
    .borderRadius({ topLeft: MeowRadius.bottomSheet, topRight: MeowRadius.bottomSheet, bottomLeft: 0, bottomRight: 0 })
    .border({ width: 1, color: MeowColors.borderSubtle })
  }

  @Builder
  private ShareSheet() {
    Column({ space: 20 }) {
      Row() {
        SheetHandle()
      }
      .width('100%')
      .height(26)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Text('Share')
        .fontSize(MeowTypography.subheadingSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')

      Column({ space: 0 }) {
        Image(this.currentTrack.artwork)
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Cover)
          .clip(true)
          .hitTestBehavior(HitTestMode.None)

        Column({ space: 6 }) {
          Text(this.currentTrack.title)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text(this.currentTrack.artist)
            .fontSize(13)
            .fontColor(MeowColors.textSecondaryStrong)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Row({ space: 6 }) {
            Image($r('app.media.meowsic_iconshare'))
              .width(16)
              .height(16)
              .objectFit(ImageFit.Contain)
            Text('PhuiSic')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(MeowColors.textTertiary)
          }
          .margin({ top: 6 })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 16, bottom: 20 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .borderRadius(MeowRadius.large)
      .backgroundColor(this.shareCardBg())
      .clip(true)
      .animation({ duration: 280, curve: Curve.EaseOut })
      .shadow({
        radius: 24,
        color: 'rgba(0,0,0,0.44)',
        offsetX: 0,
        offsetY: 10
      })

      Row({ space: 14 }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(32)
            .height(32)
            .fill(this.currentTrack.accent)
            .stroke(this.shareCardColorIndex === 0 ? MeowColors.textPrimary : MeowColors.transparent)
            .strokeWidth(2.5)
            .hitTestBehavior(HitTestMode.None)
        }
        .width(40)
        .height(40)
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => { this.shareCardColorIndex = 0 })

        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(32)
            .height(32)
            .fill('#5B2DA8')
            .stroke(this.shareCardColorIndex === 1 ? MeowColors.textPrimary : MeowColors.transparent)
            .strokeWidth(2.5)
            .hitTestBehavior(HitTestMode.None)
        }
        .width(40)
        .height(40)
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => { this.shareCardColorIndex = 1 })

        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(32)
            .height(32)
            .fill('#1a1a3a')
            .stroke(this.shareCardColorIndex === 2 ? MeowColors.textPrimary : MeowColors.transparent)
            .strokeWidth(2.5)
            .hitTestBehavior(HitTestMode.None)
        }
        .width(40)
        .height(40)
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => { this.shareCardColorIndex = 2 })

        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(32)
            .height(32)
            .fill('#050510')
            .stroke(this.shareCardColorIndex === 3 ? MeowColors.textPrimary : MeowColors.transparent)
            .strokeWidth(2.5)
            .hitTestBehavior(HitTestMode.None)
        }
        .width(40)
        .height(40)
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => { this.shareCardColorIndex = 3 })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')

      Row() {
        this.ShareButton('⧉', 'Copy Link', () => {
          const link = `https://phuisic.app/track/${this.currentTrack.id}`
          const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, link)
          pasteboard.getSystemPasteboard().setDataSync(pasteData)
          promptAction.showToast({ message: 'Link copied!', duration: 2000 })
        })
        this.ShareButton('✉', 'Message', () => {
          this.openSystemShare()
        })
        this.ShareButton('◎', 'Instagram', () => {
          this.openSystemShare()
        })
        this.ShareButton('⊕', 'More', () => {
          this.openSystemShare()
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 4, bottom: 36 })
    .backgroundColor(MeowColors.solidSurface)
    .borderRadius({ topLeft: MeowRadius.bottomSheet, topRight: MeowRadius.bottomSheet, bottomLeft: 0, bottomRight: 0 })
    .border({ width: 1, color: MeowColors.borderSubtle })
  }

  @Builder
  private QueueSheet() {
    Column({ space: 12 }) {
      Row() {
        SheetHandle()
      }
      .width('100%')
      .height(26)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      this.SheetTitleRow('Queue')

      Text('NOW PLAYING')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textTertiary)
        .width('100%')

      Row({ space: 12 }) {
        Image(this.currentTrack.artwork)
          .width(46)
          .height(46)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
          .clip(true)
          .backgroundColor(MeowColors.solidSurface)
          .hitTestBehavior(HitTestMode.None)
        Column({ space: 4 }) {
          Text(this.currentTrack.title)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTrack.accent)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.currentTrack.artist)
            .fontSize(12)
            .fontColor(MeowColors.textSecondary)
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .hitTestBehavior(HitTestMode.None)
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(36)
            .height(36)
            .borderRadius(18)
            .backgroundColor(this.currentTrack.accent)
            .hitTestBehavior(HitTestMode.None)
          if (this.isPlaying) {
            // Pause — two small vector bars (no glyph/emoji background)
            Row({ space: 4 }) {
              Column()
                .width(3)
                .height(12)
                .borderRadius(1)
                .backgroundColor(MeowColors.navyDeep)
              Column()
                .width(3)
                .height(12)
                .borderRadius(1)
                .backgroundColor(MeowColors.navyDeep)
            }
            .hitTestBehavior(HitTestMode.None)
          } else {
            // Play — small vector triangle (no glyph/emoji background)
            Path()
              .width(11)
              .height(13)
              .commands('M0 0 L11 6.5 L0 13 Z')
              .fill(MeowColors.navyDeep)
              .stroke(MeowColors.transparent)
              .translate({ x: 1 })
              .hitTestBehavior(HitTestMode.None)
          }
        }
        .width(40)
        .height(40)
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => {
          this.togglePlay()
        })
      }
      .width('100%')
      .height(58)
      .padding({ left: 12, right: 12 })
      .borderRadius(MeowRadius.card)
      .backgroundColor(this.currentTrack.accentSoft)
      .border({ width: 1, color: MeowColors.borderStrong })
      .alignItems(VerticalAlign.Center)

      Text('UP NEXT')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textTertiary)
        .width('100%')

      Scroll() {
        Column({ space: 0 }) {
          ForEach(this.upcomingTracks(), (track: Track) => {
            Row({ space: 12 }) {
              Image(track.artwork)
                .width(44)
                .height(44)
                .borderRadius(10)
                .objectFit(ImageFit.Cover)
                .clip(true)
                .backgroundColor(MeowColors.solidSurface)
                .hitTestBehavior(HitTestMode.None)
              Column({ space: 4 }) {
                Text(track.title)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(MeowColors.textPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(track.artist)
                  .fontSize(12)
                  .fontColor(MeowColors.textSecondary)
                  .maxLines(1)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .hitTestBehavior(HitTestMode.None)
              Text('≡')
                .fontSize(18)
                .fontColor(MeowColors.textTertiary)
                .width(28)
                .textAlign(TextAlign.Center)
                .hitTestBehavior(HitTestMode.None)
            }
            .width('100%')
            .height(58)
            .alignItems(VerticalAlign.Center)
            .hitTestBehavior(HitTestMode.Block)
            .onClick(() => {
              PlayerManager.playTrack(track)
              this.dismissSheets()
            })
          }, (track: Track) => track.id)
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .constraintSize({ maxHeight: 240 })
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 36 })
    .backgroundColor(MeowColors.solidSurface)
    .borderRadius({ topLeft: MeowRadius.bottomSheet, topRight: MeowRadius.bottomSheet, bottomLeft: 0, bottomRight: 0 })
    .border({ width: 1, color: MeowColors.borderSubtle })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [this.currentTrack.accentSoft, 0.0],
            [MeowColors.navyDeep, 1.0]
          ]
        })
        .animation({ duration: 500, curve: Curve.EaseInOut })
        .hitTestBehavior(HitTestMode.None)

      Scroll() {
        Column({ space: 16 }) {
          this.TopBar()
          this.CoverStage()
          this.SongInfoRow()
          this.Progress()
          this.Controls()
          this.BottomActions()
          LyricsCard({
            clickAction: () => {
              this.lyricsExpanded = !this.lyricsExpanded
            }
          })
            .margin({ top: 28 })
          if (this.lyricsExpanded) {
            this.ExpandedLyrics(this.activeLyricIndex())
          }
          this.ArtistInfoCard()
          this.ExploreArtist()
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 28, bottom: MeowSpacing.playerContentBottomPadding })
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .zIndex(1)

      if (this.showConnectSheet || this.showShareSheet || this.showQueueSheet || this.showMenuSheet) {
        Stack({ alignContent: Alignment.Bottom }) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0,0,0,0.56)')
            .onClick(() => { this.dismissSheets() })

          Column() {
            if (this.showMenuSheet) {
              this.MenuSheet()
            } else if (this.showConnectSheet) {
              this.ConnectSheet()
            } else if (this.showShareSheet) {
              this.ShareSheet()
            } else {
              this.QueueSheet()
            }
          }
          .width('100%')
          .onClick(() => {})
        }
        .width('100%')
        .height('100%')
        .zIndex(20)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MeowColors.navyDeep)
    .expandSafeArea([SafeAreaType.SYSTEM])
  }
}
