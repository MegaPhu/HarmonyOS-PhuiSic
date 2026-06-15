import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DEFAULT_TRACK, Track } from '../model/MusicData'
import { PlayerManager } from '../model/PlayerManager'
import { MeowColors, MeowEffects, MeowRadius } from '../theme/theme'

@Preview
@Component
export struct MiniPlayer {
  @StorageLink('currentTrack') currentTrack: Track = DEFAULT_TRACK
  @StorageLink('isPlaying') isPlaying: boolean = false
  @StorageLink('likedTrackIds') likedTrackIds: string = ''
  @StorageLink('currentTimeSeconds') private elapsedSeconds: number = 0
  @StorageLink('currentTrackId') private currentTrackId: string = ''
  @State private playPressed: boolean = false

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
      Row()
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor('rgba(255,255,255,0.07)')
        .border({ width: 1, color: 'rgba(255,255,255,0.12)' })
        .hitTestBehavior(HitTestMode.None)
      Text('⊙')
        .fontSize(18)
        .fontColor(MeowColors.textSecondary)
        .textAlign(TextAlign.Center)
        .hitTestBehavior(HitTestMode.None)
    }
    .width(44)
    .height(44)
    .hitTestBehavior(HitTestMode.Block)
    .onClick(() => {
      promptAction.showToast({ message: 'Connect to device: Coming soon', duration: 2000 })
    })
  }

  @Builder
  private AddLibraryButton() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(30)
        .height(30)
        .fill(this.currentTrackLiked() ? this.currentTrack.accent : 'transparent')
        .stroke(this.currentTrackLiked() ? this.currentTrack.accent : MeowColors.textSecondary)
        .strokeWidth(1.8)
        .hitTestBehavior(HitTestMode.None)
      Text(this.currentTrackLiked() ? '✓' : '+')
        .fontSize(this.currentTrackLiked() ? 15 : 20)
        .fontWeight(this.currentTrackLiked() ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTrackLiked() ? MeowColors.navyDeep : MeowColors.textSecondary)
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
  private PlayPauseButton() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.isPlaying ? 'Ⅱ' : '▶')
        .fontSize(this.isPlaying ? 22 : 24)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .textAlign(TextAlign.Center)
        .translate({ x: this.isPlaying ? 0 : 2 })
        .shadow(this.playPressed
          ? { radius: 10, color: this.currentTrack.accent, offsetX: 0, offsetY: 0 }
          : { radius: 0, color: MeowColors.transparent, offsetX: 0, offsetY: 0 })
        .hitTestBehavior(HitTestMode.None)
    }
    .width(48)
    .height(48)
    .scale({ x: this.playPressed ? 0.88 : 1, y: this.playPressed ? 0.88 : 1 })
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
          .width(60)
          .height(60)
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
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.openPlayer()
          })

        Column({ space: 4 }) {
          Text(this.currentTrack.title)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
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

        Row({ space: 0 }) {
          this.ConnectButton()
          this.AddLibraryButton()
          this.PlayPauseButton()
        }
        .padding({ right: 8 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(80)
    .linearGradient({
      angle: 90,
      colors: [
        [this.currentTrack.accentSoft, 0.0],
        [MeowColors.miniPlayerOverlay, 0.45]
      ]
    })
    .border({ width: 1, color: MeowColors.borderSoft })
    .borderRadius(20)
    .clip(true)
    .backdropBlur(MeowEffects.backdropBlur)
    .shadow({
      radius: 28,
      color: this.currentTrack.accentSoft,
      offsetX: 0,
      offsetY: 10
    })
    .visibility(this.playerVisibility())
  }
}
