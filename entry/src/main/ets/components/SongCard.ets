import router from '@ohos.router'
import { DEFAULT_TRACK, Track } from '../model/MusicData'
import { PlayerManager } from '../model/PlayerManager'
import { MeowColors, MeowRadius, MeowTypography } from '../theme/theme'

@Preview
@Component
export struct SongCard {
  @Prop track: Track = DEFAULT_TRACK
  @Prop compact: boolean = false
  @StorageLink('likedTrackIds') likedTrackIds: string = ''

  private async openPlayer(): Promise<void> {
    console.log(`[SongCard] open ${this.track.title}`)
    PlayerManager.playTrack(this.track)
    const state = router.getState()
    if (state.name !== 'Player') {
      await router.pushUrl({ url: 'pages/main/Player' })
    }
  }

  private async openArtistPage(): Promise<void> {
    console.log(`[SongCard] open artist ${this.track.artist}`)
    await router.pushUrl({ url: 'pages/main/ArtistSongs', params: { artist: this.track.artist } })
  }

  private trackLiked(): boolean {
    return PlayerManager.isLiked(this.track, this.likedTrackIds)
  }

  @Builder
  private Cover(sizeValue: number) {
    Image(this.track.artwork)
      .width(sizeValue)
      .height(sizeValue)
      .borderRadius(this.compact ? 10 : 12)
      .objectFit(ImageFit.Cover)
      .clip(true)
      .backgroundColor(MeowColors.solidSurface)
      .border({ width: 1, color: MeowColors.borderSubtle })
  }

  @Builder
  private LikeButton(liked: boolean) {
    Stack({ alignContent: Alignment.Center }) {
      Text(liked ? '♥' : '♡')
        .fontSize(this.compact ? 20 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor(liked ? this.track.accent : MeowColors.textSecondary)
    }
      .width(44)
      .height(44)
      .borderRadius(MeowRadius.card)
      .backgroundColor(liked ? this.track.accentSoft : MeowColors.glassBgSoft)
      .onClick(() => {
        console.log(`[SongCard] toggle like ${this.track.title}`)
        PlayerManager.toggleLikedInStorage(this.track, this.likedTrackIds)
      })
  }

  build() {
    Row({ space: 12 }) {
      this.Cover(this.compact ? 54 : 64)

      Column({ space: 5 }) {
        Text(this.track.title)
          .fontSize(this.compact ? 14 : 16)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.track.artist)
          .fontSize(MeowTypography.captionSize)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .onClick(() => {
            this.openArtistPage()
          })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 2 }) {
        this.LikeButton(this.trackLiked())
        Text(this.track.durationLabel)
          .fontSize(MeowTypography.captionSize)
          .fontColor(MeowColors.textTertiary)
          .width(42)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width(this.compact ? 236 : '100%')
    .height(this.compact ? 78 : 88)
    .padding({ left: 12, right: 14, top: 12, bottom: 12 })
    .borderRadius(this.compact ? 14 : MeowRadius.card)
    .backgroundColor(MeowColors.solidSurface)
    .border({ width: 1, color: MeowColors.borderSubtle })
    .onClick(() => {
      this.openPlayer()
    })
  }
}
