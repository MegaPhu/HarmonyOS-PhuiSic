import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DEFAULT_TRACK, Track } from '../model/MusicData'
import { PlayerManager } from '../model/PlayerManager'
import { MeowColors, MeowPlayer, MeowRadius } from '../theme/theme'

@Preview
@Component
export struct MiniPlayer {
  @StorageLink('currentTrack') currentTrack: Track = DEFAULT_TRACK
  @StorageLink('isPlaying') isPlaying: boolean = false
  @StorageLink('likedTrackIds') likedTrackIds: string = ''
  @StorageLink('currentTimeSeconds') private elapsedSeconds: number = 0
  @StorageLink('currentTrackId') private currentTrackId: string = ''
  @State private playPressed: boolean = false
  // Horizontal swipe-to-change-track slide state (driven by animateTo).
  @State private cardShift: number = 0
  @State private cardFade: number = 1
  private isSwiping: boolean = false
  private lastSwipeMs: number = 0

  private async openPlayer(): Promise<void> {
    const state = router.getState()
    if (state.name === 'Player') {
      return
    }
    await router.pushUrl({ url: 'pages/main/Player' })
  }

  private togglePlay(): void {
    PlayerManager.togglePlay(this.isPlaying)
  }

  // Slide the mini player content out (swipe-left → next slides left, swipe-
  // right → previous slides right), swap the track while it is invisible, then
  // slide the new track in from the opposite side. An interaction lock plus a
  // debounce window ignores further swipes until the animation completes, so a
  // rapid flurry of swipes can never desync the track. PlayerManager handles
  // currentTrack / currentTrackId / currentTimeSeconds(=0) / isPlaying.
  private swipeTrack(dir: number, applyChange: () => void): void {
    const now = Date.now()
    if (this.isSwiping || now - this.lastSwipeMs < 220) {
      return
    }
    this.lastSwipeMs = now
    this.isSwiping = true
    const dist = 60
    animateTo({ duration: 130, curve: Curve.EaseIn, onFinish: () => {
      applyChange()
      animateTo({ duration: 0 }, () => {
        this.cardShift = dir * dist
      })
      animateTo({ duration: 210, curve: Curve.EaseOut, onFinish: () => {
        this.isSwiping = false
      } }, () => {
        this.cardShift = 0
        this.cardFade = 1
      })
    } }, () => {
      this.cardShift = -dir * dist
      this.cardFade = 0
    })
  }

  private swipeNext(): void {
    this.swipeTrack(1, () => {
      PlayerManager.playNext(this.currentTrack, this.isPlaying)
    })
  }

  private swipePrevious(): void {
    this.swipeTrack(-1, () => {
      PlayerManager.playPrevious(this.currentTrack, this.isPlaying)
    })
  }

  private toggleLike(): void {
    PlayerManager.toggleLikedInStorage(this.currentTrack, this.likedTrackIds)
  }

  private currentTrackLiked(): boolean {
    return PlayerManager.isLiked(this.currentTrack, this.likedTrackIds)
  }

  private progressFraction(): number {
    if (this.currentTrack.duration <= 0) {
      return 0
    }
    return Math.min(this.elapsedSeconds / this.currentTrack.duration, 1)
  }

  private playerVisibility(): Visibility {
    return this.currentTrackId.length > 0 ? Visibility.Visible : Visibility.Hidden
  }

  @Builder
  private ConnectButton() {
    Stack({ alignContent: Alignment.Center }) {
      // Connect-to-device icon — two overlapping rounded-rect devices (white,
      // no circle background), matching the reference.
      Row()
        .width(MeowPlayer.miniActionIcon - 6)
        .height(MeowPlayer.miniActionIcon)
        .borderRadius(4)
        .border({ width: 2, color: MeowColors.textPrimary })
        .translate({ x: -4, y: -2 })
        .hitTestBehavior(HitTestMode.None)
      Row()
        .width(MeowPlayer.miniActionIcon - 10)
        .height(MeowPlayer.miniActionIcon - 6)
        .borderRadius(3)
        .backgroundColor(MeowColors.miniPlayerOverlay)
        .border({ width: 2, color: MeowColors.textPrimary })
        .translate({ x: 6, y: 4 })
        .hitTestBehavior(HitTestMode.None)
      Row()
        .width(4)
        .height(4)
        .borderRadius(2)
        .backgroundColor(MeowColors.textPrimary)
        .translate({ x: 6, y: 5 })
        .hitTestBehavior(HitTestMode.None)
    }
    .width(MeowPlayer.miniActionTap)
    .height(MeowPlayer.miniActionTap)
    .hitTestBehavior(HitTestMode.Block)
    .onClick(() => {
      promptAction.showToast({ message: 'Connect to device: Coming soon', duration: 2000 })
    })
  }

  @Builder
  private AddLibraryButton() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(MeowPlayer.miniActionTap - 10)
        .height(MeowPlayer.miniActionTap - 10)
        .fill(this.currentTrackLiked() ? this.currentTrack.accent : 'transparent')
        .stroke(this.currentTrackLiked() ? this.currentTrack.accent : MeowColors.textSecondary)
        .strokeWidth(1.4)
        .hitTestBehavior(HitTestMode.None)
      Text(this.currentTrackLiked() ? '✓' : '+')
        .fontSize(this.currentTrackLiked() ? 16 : 21)
        .fontWeight(this.currentTrackLiked() ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTrackLiked() ? MeowColors.navyDeep : MeowColors.textSecondary)
        .textAlign(TextAlign.Center)
        .hitTestBehavior(HitTestMode.None)
    }
    .width(MeowPlayer.miniActionTap)
    .height(MeowPlayer.miniActionTap)
    .hitTestBehavior(HitTestMode.Block)
    .onClick(() => {
      this.toggleLike()
    })
  }

  @Builder
  private PlayPauseButton() {
    // Primary — solid white circle with a dark glyph. Opaque circle = tap target.
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(MeowPlayer.miniPlayTap)
        .height(MeowPlayer.miniPlayTap)
        .fill(MeowColors.textPrimary)
        .hitTestBehavior(HitTestMode.None)
        .shadow(this.playPressed
          ? { radius: 10, color: this.currentTrack.accent, offsetX: 0, offsetY: 0 }
          : { radius: 6, color: 'rgba(0,0,0,0.26)', offsetX: 0, offsetY: 3 })
      if (this.isPlaying) {
        // Pause — system symbol (correct proportions, no taper / no padding).
        SymbolGlyph($r('sys.symbol.pause_fill'))
          .fontSize(MeowPlayer.miniPlayIcon - 2)
          .fontColor([MeowColors.navyDeep])
          .hitTestBehavior(HitTestMode.None)
      } else {
        // Play — system symbol (correct proportions, no taper / no padding).
        SymbolGlyph($r('sys.symbol.play_fill'))
          .fontSize(MeowPlayer.miniPlayIcon)
          .fontColor([MeowColors.navyDeep])
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width(MeowPlayer.miniPlayTap)
    .height(MeowPlayer.miniPlayTap)
    .scale({ x: this.playPressed ? 0.9 : 1, y: this.playPressed ? 0.9 : 1 })
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

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Row()
        .width(`${this.progressFraction() * 100}%`)
        .height(3)
        .backgroundColor(this.currentTrack.accent)
        .borderRadius(1.5)
        .zIndex(5)
        .hitTestBehavior(HitTestMode.None)

      Row({ space: 10 }) {
        Image(this.currentTrack.artwork)
          .width(MeowPlayer.miniCoverSize)
          .height(MeowPlayer.miniCoverSize)
          .objectFit(ImageFit.Cover)
          .borderRadius(MeowRadius.control)
          .clip(true)
          .backgroundColor(MeowColors.solidSurface)
          .shadow({
            radius: 12,
            color: this.currentTrack.accentSoft,
            offsetX: 0,
            offsetY: 4
          })
          .margin({ left: 10 })
          .scale({
            x: this.isPlaying ? MeowPlayer.albumPlayingScale : 1,
            y: this.isPlaying ? MeowPlayer.albumPlayingScale : 1
          })
          .animation({ duration: MeowPlayer.albumZoomDuration, curve: Curve.EaseOut })
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.openPlayer()
          })

        Column({ space: 4 }) {
          Text(this.currentTrack.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(MeowColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.currentTrack.artist)
            .fontSize(12)
            .fontColor(MeowColors.textSecondaryStrong)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => {
          this.openPlayer()
        })

        Row({ space: 10 }) {
          this.ConnectButton()
          this.AddLibraryButton()
          this.PlayPauseButton()
        }
        .padding({ left: 0, right: 8 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(MeowPlayer.miniCardHeight)
      .alignItems(VerticalAlign.Center)
      .translate({ x: this.cardShift })
      .opacity(this.cardFade)
    }
    .width('100%')
    .height(MeowPlayer.miniCardHeight)
    .linearGradient({
      angle: 90,
      colors: [
        ['rgba(20,21,40,0.98)', 0.0],
        [MeowColors.miniPlayerOverlay, 0.62],
        [MeowColors.navyDeep, 1.0]
      ]
    })
    .border({ width: 1, color: 'rgba(255,255,255,0.12)' })
    .borderRadius(20)
    .clip(true)
    .shadow({
      radius: 22,
      color: MeowColors.shadowMiniPlayer,
      offsetX: 0,
      offsetY: 8
    })
    .visibility(this.playerVisibility())
    .parallelGesture(
      PanGesture({ direction: PanDirection.Horizontal, distance: 12 })
        .onActionEnd((event: GestureEvent) => {
          if (event.offsetX <= -56) {
            this.swipeNext()
          } else if (event.offsetX >= 56) {
            this.swipePrevious()
          }
        })
    )
  }
}
