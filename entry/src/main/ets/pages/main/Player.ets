import router from '@ohos.router'
import { LyricsCard } from '../../components/LyricsCard'
import { DEFAULT_TRACK, MUSIC_TRACKS, Track } from '../../model/MusicData'
import { PlayerManager } from '../../model/PlayerManager'
import { AudioEngine } from '../../model/AudioEngine'
import { MeowColors, MeowEffects, MeowRadius, MeowSpacing, MeowTypography } from '../../theme/theme'
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
  @StorageLink('isPlaying') isPlaying: boolean = false
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
  @State private cachedLyrics: LyricLine[] = []
  private prevTrackId: string = ''
  private lastTrackChangeMs: number = 0

  aboutToAppear(): void {
    this.elapsedSeconds = Math.max(0, Math.min(this.elapsedSeconds, this.currentTrack.duration))
    this.prevTrackId = this.currentTrack.id
    this.cachedLyrics = this.buildLyrics()
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
    let activeIndex = 0
    const elapsedMs = seconds * 1000
    for (let i = 0; i < this.currentTrack.timestamps.length; i++) {
      if (elapsedMs >= this.currentTrack.timestamps[i]) {
        activeIndex = i
      }
    }
    return Math.min(activeIndex, this.currentTrack.lyrics.length - 1)
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

  private previousTrack(): void {
    const now = Date.now()
    if (now - this.lastTrackChangeMs < 150) {
      return
    }
    this.lastTrackChangeMs = now
    this.shuffleEnabled = false
    this.repeatEnabled = 0
    PlayerManager.playPrevious(this.currentTrack, this.isPlaying)
    this.resetPlaybackPosition()
    this.lyricsExpanded = false
    console.log('[PlayerPage] previous track')
  }

  private nextTrack(): void {
    const now = Date.now()
    if (now - this.lastTrackChangeMs < 150) {
      return
    }
    this.lastTrackChangeMs = now
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
    this.resetPlaybackPosition()
    this.lyricsExpanded = false
    console.log('[PlayerPage] next track')
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
    }
    .width('100%')
    .aspectRatio(1)
    .borderRadius(MeowRadius.large)
    .shadow({
      radius: 28,
      color: this.currentTrack.accentSoft,
      offsetX: 0,
      offsetY: 10
    })
    .scale({
      x: this.isPlaying ? 0.85 : 1,
      y: this.isPlaying ? 0.85 : 1
    })
    .animation({ duration: 450, curve: Curve.Friction })
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

  @Builder
  private AddLibraryIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(38)
        .height(38)
        .fill(this.currentTrackLiked() ? this.currentTrack.accentSoft : 'transparent')
        .stroke(this.currentTrackLiked() ? this.currentTrack.accent : 'rgba(255,255,255,0.44)')
        .strokeWidth(1.8)
        .hitTestBehavior(HitTestMode.None)
      Text(this.currentTrackLiked() ? '✓' : '+')
        .fontSize(this.currentTrackLiked() ? 18 : 24)
        .fontWeight(this.currentTrackLiked() ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTrackLiked() ? this.currentTrack.accent : MeowColors.textPrimary)
        .textAlign(TextAlign.Center)
        .hitTestBehavior(HitTestMode.None)
    }
    .width(44)
    .height(44)
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
          .fontSize(21)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.currentTrack.artist)
          .fontSize(14)
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
  }

  @Builder
  private Progress() {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width('100%')
          .height(4)
          .borderRadius(2)
          .backgroundColor(MeowColors.borderGhost)
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
    Stack({ alignContent: Alignment.Center }) {
      Text(this.isPlaying ? 'Ⅱ' : '▶')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.navyDeep)
    }
    .width(60)
    .height(60)
    .borderRadius(30)
    .backgroundColor(MeowColors.textPrimary)
    .shadow({
      radius: this.isPlaying ? MeowEffects.glowBlur : 0,
      color: this.isPlaying ? this.currentTrack.accentSoft : 'rgba(0,0,0,0)',
      offsetX: 0,
      offsetY: 0
    })
    .animation({ duration: 500, curve: Curve.EaseInOut })
    .hitTestBehavior(HitTestMode.Block)
    .onClick(() => {
      this.togglePlay()
    })
  }

  @Builder
  private Controls() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Column({ space: 3 }) {
          Text('⇄')
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.shuffleEnabled ? this.currentTrack.accent : MeowColors.textSecondary)
            .textAlign(TextAlign.Center)
            .hitTestBehavior(HitTestMode.None)
          Row()
            .width(5)
            .height(5)
            .borderRadius(2.5)
            .backgroundColor(this.shuffleEnabled ? this.currentTrack.accent : MeowColors.transparent)
            .hitTestBehavior(HitTestMode.None)
        }
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.None)
      }
      .width(46)
      .height(46)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => { this.toggleShuffle() })

      Stack({ alignContent: Alignment.Center }) {
        Text('‹')
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textSecondary)
          .textAlign(TextAlign.Center)
          .opacity(0.84)
          .hitTestBehavior(HitTestMode.None)
      }
      .width(46)
      .height(46)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => { this.previousTrack() })

      this.PlayPauseButton()

      Stack({ alignContent: Alignment.Center }) {
        Text('›')
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textSecondary)
          .textAlign(TextAlign.Center)
          .opacity(0.84)
          .hitTestBehavior(HitTestMode.None)
      }
      .width(46)
      .height(46)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => { this.nextTrack() })

      Stack({ alignContent: Alignment.Center }) {
        Column({ space: 2 }) {
          Text('↻')
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.repeatEnabled > 0 ? this.currentTrack.accent : MeowColors.textSecondary)
            .textAlign(TextAlign.Center)
            .hitTestBehavior(HitTestMode.None)
          if (this.repeatEnabled === 2) {
            Text('1')
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentTrack.accent)
              .textAlign(TextAlign.Center)
              .hitTestBehavior(HitTestMode.None)
          } else {
            Row()
              .width(5)
              .height(5)
              .borderRadius(2.5)
              .backgroundColor(this.repeatEnabled === 1 ? this.currentTrack.accent : MeowColors.transparent)
              .hitTestBehavior(HitTestMode.None)
          }
        }
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.None)
      }
      .width(46)
      .height(46)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => { this.toggleRepeat() })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  private ShareActionIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(18)
        .height(2)
        .borderRadius(1)
        .backgroundColor(MeowColors.textSecondary)
        .rotate({ angle: -32 })
        .translate({ x: 0, y: -2 })
      Row()
        .width(18)
        .height(2)
        .borderRadius(1)
        .backgroundColor(MeowColors.textSecondary)
        .rotate({ angle: 28 })
        .translate({ x: 0, y: 5 })
      Circle()
        .width(6)
        .height(6)
        .fill(MeowColors.textSecondary)
        .translate({ x: -9, y: 7 })
      Circle()
        .width(6)
        .height(6)
        .fill(MeowColors.textSecondary)
        .translate({ x: 8, y: -8 })
      Circle()
        .width(6)
        .height(6)
        .fill(MeowColors.textSecondary)
        .translate({ x: 10, y: 9 })
    }
    .width(44)
    .height(44)
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  private QueueActionIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(22)
        .height(2.4)
        .borderRadius(1.2)
        .backgroundColor(MeowColors.textSecondary)
        .translate({ x: 0, y: -7 })
      Row()
        .width(22)
        .height(2.4)
        .borderRadius(1.2)
        .backgroundColor(MeowColors.textSecondary)
      Row()
        .width(22)
        .height(2.4)
        .borderRadius(1.2)
        .backgroundColor(MeowColors.textSecondary)
        .translate({ x: 0, y: 7 })
    }
    .width(44)
    .height(44)
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  private BottomAction(label: string, action: () => void) {
    Column({ space: 3 }) {
      if (label === 'Connect') {
        this.DeviceActionIcon()
      } else if (label === 'Share') {
        this.ShareActionIcon()
      } else {
        this.QueueActionIcon()
      }

      Text(label)
        .fontSize(10)
        .fontColor(MeowColors.textTertiary)
    }
    .width(72)
    .height(62)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
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
    .width('100%')
    .height(62)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  private DeviceActionIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(16)
        .height(22)
        .borderRadius(4)
        .border({ width: 2, color: MeowColors.textSecondary })
      Row()
        .width(5)
        .height(5)
        .borderRadius(3)
        .backgroundColor(MeowColors.textSecondary)
        .translate({ x: 0, y: 7 })
      Row()
        .width(12)
        .height(16)
        .borderRadius(3)
        .border({ width: 2, color: MeowColors.textSecondary })
        .translate({ x: -11, y: 4 })
    }
    .width(44)
    .height(44)
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
    .border({ width: 1, color: 'rgba(255,255,255,0.075)' })
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
        this.SheetHandle()
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
    .borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 })
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
  private SheetHandle() {
    Row()
      .width(40)
      .height(4)
      .borderRadius(2)
      .backgroundColor('rgba(255,255,255,0.22)')
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
        this.SheetHandle()
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
    .borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 })
    .border({ width: 1, color: MeowColors.borderSubtle })
  }

  @Builder
  private ShareSheet() {
    Column({ space: 20 }) {
      Row() {
        this.SheetHandle()
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
    .borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 })
    .border({ width: 1, color: MeowColors.borderSubtle })
  }

  @Builder
  private QueueSheet() {
    Column({ space: 12 }) {
      Row() {
        this.SheetHandle()
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
          Text(this.isPlaying ? 'Ⅱ' : '▶')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.navyDeep)
            .textAlign(TextAlign.Center)
            .translate({ x: this.isPlaying ? 0 : 1 })
            .hitTestBehavior(HitTestMode.None)
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
    .borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 })
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
        Column({ space: 18 }) {
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
          if (this.lyricsExpanded) {
            this.ExpandedLyrics(this.activeLyricIndex())
          }
          this.ArtistInfoCard()
          this.ExploreArtist()
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 34, bottom: MeowSpacing.mainContentBottomPadding })
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
