import router from '@ohos.router'
import { BottomNavBar } from '../../components/BottomNavBar'
import { MiniPlayer } from '../../components/MiniPlayer'
import { DEFAULT_TRACK, MUSIC_TRACKS, Track } from '../../model/MusicData'
import { PlayerManager } from '../../model/PlayerManager'
import { MeowColors, MeowRadius, MeowSpacing, MeowTypography } from '../../theme/theme'
import { SheetHandle } from '../../components/SheetHandle'

@Entry
@Component
struct ArtistSongs {
  @StorageLink('currentTrack') currentTrack: Track = DEFAULT_TRACK
  @StorageLink('isPlaying') isPlaying: boolean = false
  @State private activeTab: string = 'Music'
  @StorageLink('followedArtistIds') private followedArtistIds: string = ''
  @StorageLink('shuffleEnabled') private shuffleEnabled: boolean = false
  @State private viewArtist: string = ''
  @State private showMenuSheet: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params) {
      const a = params['artist']
      if (a && a.length > 0) {
        this.viewArtist = a
      }
    }
  }

  private effectiveArtist(): string {
    return this.viewArtist.length > 0 ? this.viewArtist : this.currentTrack.artist
  }

  private repTrack(): Track {
    const artist = this.effectiveArtist()
    const found = MUSIC_TRACKS.find((t: Track): boolean => t.artist === artist)
    return found ?? this.currentTrack
  }

  private closePage(): void {
    console.log('[ArtistSongsPage] back')
    router.back()
  }

  private playTrack(track: Track): void {
    console.log(`[ArtistSongsPage] play ${track.title}`)
    PlayerManager.playTrack(track)
  }

  private async openFirstArtistTrack(): Promise<void> {
    const tracks = this.artistTracks()
    if (tracks.length > 0) {
      this.playTrack(tracks[0])
    }
    const state = router.getState()
    if (state.name === 'Player') {
      return
    }
    await router.pushUrl({ url: 'pages/main/Player' })
  }

  private togglePlay(): void {
    console.log('[ArtistSongsPage] toggle play')
    PlayerManager.togglePlay(this.isPlaying)
  }

  private artistTracks(): Track[] {
    return MUSIC_TRACKS.filter((t: Track): boolean => t.artist === this.effectiveArtist())
  }

  @Builder
  private BackButton() {
    Text('‹')
      .fontSize(42)
      .fontWeight(FontWeight.Bold)
      .fontColor(MeowColors.textPrimary)
      .width(44)
      .height(44)
      .textAlign(TextAlign.Center)
      .borderRadius(22)
      .backgroundColor('rgba(9,10,28,0.52)')
      .onClick(() => {
        this.closePage()
      })
  }

  @Builder
  private Header() {
    Stack() {
      Image(this.repTrack().artwork)
        .width('100%')
        .height(310)
        .objectFit(ImageFit.Cover)
        .opacity(0.82)

      Column()
        .width('100%')
        .height(200)
        .linearGradient({
          angle: 180,
          colors: [
            ['rgba(9,10,28,0)', 0.0],
            [MeowColors.navyDeep, 1.0]
          ]
        })
        .position({ x: 0, y: 110 })

      Column() {
        Row() {
          this.BackButton()
        }
        .width('100%')
        .padding({ left: 16, top: 36 })

        Blank()

        Column({ space: 5 }) {
          Text(this.effectiveArtist())
            .fontSize(MeowTypography.displaySize)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text(`${this.repTrack().listeners} monthly listeners`)
            .fontSize(13)
            .fontColor(MeowColors.textSecondary)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 22, right: 22, bottom: 20 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(310)
    }
    .width('100%')
    .height(310)
  }

  @Builder
  private FollowButton() {
    Text(PlayerManager.isFollowed(this.effectiveArtist(), this.followedArtistIds)
      ? 'Following' : 'Follow')
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(MeowColors.textPrimary)
      .padding({ left: 20, right: 20, top: 7, bottom: 7 })
      .borderRadius(MeowRadius.chipPill)
      .border({ width: 1, color: 'rgba(255,255,255,0.72)' })
      .onClick(() => {
        PlayerManager.toggleFollowedInStorage(this.effectiveArtist(), this.followedArtistIds)
        console.log(`[ArtistSongsPage] follow toggled ${this.effectiveArtist()}`)
      })
  }

  @Builder
  private ControlsRow() {
    Row() {
      Image(this.repTrack().artwork)
        .width(42)
        .height(42)
        .borderRadius(21)
        .objectFit(ImageFit.Cover)
        .clip(true)
        .border({ width: 1, color: MeowColors.borderSoft })
        .margin({ right: 12 })

      this.FollowButton()

      Text('⋮')
        .fontSize(22)
        .fontColor(MeowColors.textSecondary)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .margin({ left: 6 })
        .onClick(() => {
          this.showMenuSheet = true
        })

      Blank()

      Text('⇄')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.shuffleEnabled ? MeowColors.goldBright : MeowColors.textSecondary)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.shuffleEnabled = !this.shuffleEnabled
        })

      Stack({ alignContent: Alignment.Center }) {
        Text(this.isPlaying ? 'Ⅱ' : '▶')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.navyDeep)
          .translate({ x: this.isPlaying ? 0 : 2, y: 0 })
      }
      .width(62)
      .height(62)
      .borderRadius(31)
      .linearGradient({
        angle: 135,
        colors: [
          [MeowColors.goldDark, 0.0],
          [MeowColors.goldBright, 0.42],
          [MeowColors.goldSoft, 1.0]
        ]
      })
      .shadow({ radius: 12, color: MeowColors.goldBright, offsetX: 0, offsetY: 4 })
      .onClick(() => {
        const tracks = this.artistTracks()
        if (tracks.length > 0 && this.currentTrack.artist !== this.effectiveArtist()) {
          this.playTrack(tracks[0])
        } else {
          this.togglePlay()
        }
      })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 16, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private ReleaseBanner() {
    Row({ space: 12 }) {
      Image(this.repTrack().artwork)
        .width(42)
        .height(42)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)
        .clip(true)
      Text('Listen to new releases')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .layoutWeight(1)
      Text('›')
        .fontSize(MeowTypography.displaySize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textSecondary)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .borderRadius(8)
    .backgroundColor('rgba(28,28,58,0.78)')
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
    .onClick(async () => {
      await this.openFirstArtistTrack()
    })
  }

  @Builder
  private TabItem(label: string) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.activeTab === label ? MeowColors.textPrimary : MeowColors.textSecondary)
      Row()
        .width(this.activeTab === label ? 36 : 0)
        .height(2)
        .borderRadius(1)
        .backgroundColor(this.activeTab === label ? MeowColors.goldBright : 'rgba(0,0,0,0)')
    }
    .height(38)
    .onClick(() => {
      console.log(`[ArtistSongsPage] tab ${label}`)
      this.activeTab = label
    })
  }

  @Builder
  private Tabs() {
    Row({ space: 36 }) {
      this.TabItem('Music')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10 })
  }

  @Builder
  private PopularRow(track: Track, index: number) {
    Row({ space: 12 }) {
      Text(`${index + 1}`)
        .fontSize(14)
        .fontColor(MeowColors.textSecondary)
        .width(24)
      Image(track.artwork)
        .width(44)
        .height(44)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)
        .clip(true)
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(track.title)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        Text(track.plays)
          .fontSize(12)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('⋮')
        .fontSize(22)
        .fontColor(MeowColors.textSecondary)
    }
    .width('100%')
    .height(58)
    .alignItems(VerticalAlign.Center)
    .onClick(async () => {
      this.playTrack(track)
      const state = router.getState()
      if (state.name === 'Player') {
        return
      }
      await router.pushUrl({ url: 'pages/main/Player' })
    })
  }

  @Builder
  private PopularList() {
    Column({ space: 8 }) {
      Text('Popular')
        .fontSize(MeowTypography.titleSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')
        .padding({ left: 16, right: 16 })
      if (this.activeTab === 'Music') {
        if (this.artistTracks().length === 0) {
          Column({ space: 6 }) {
            Text('No songs available')
              .fontSize(14)
              .fontColor(MeowColors.textSecondary)
              .textAlign(TextAlign.Center)
            Text(this.viewArtist)
              .fontSize(MeowTypography.captionSize)
              .fontColor(MeowColors.textTertiary)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ top: 32, bottom: 32 })
          .alignItems(HorizontalAlign.Center)
        } else {
          ForEach(this.artistTracks(), (track: Track, index: number) => {
            this.PopularRow(track, index)
          }, (track: Track) => track.id)
        }
      } else {
        Text('No clips available for this artist.')
          .fontSize(14)
          .fontColor(MeowColors.textSecondary)
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 32, bottom: 32 })
      }
    }
    .width('100%')
  }

  @Builder
  private ArtistMenuSheet() {
    Column({ space: 0 }) {
      SheetHandle()
        .margin({ bottom: 16 })

      Row({ space: 14 }) {
        Image(this.repTrack().artwork)
          .width(52)
          .height(52)
          .borderRadius(MeowRadius.control)
          .objectFit(ImageFit.Cover)
          .clip(true)
          .backgroundColor(MeowColors.solidSurface)
        Column({ space: 4 }) {
          Text(this.effectiveArtist())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('Artist')
            .fontSize(13)
            .fontColor(MeowColors.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
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

      Row({ space: 18 }) {
        Text(PlayerManager.isFollowed(this.effectiveArtist(), this.followedArtistIds) ? '♥' : '♡')
          .fontSize(20)
          .fontColor(MeowColors.textSecondary)
          .width(28)
          .textAlign(TextAlign.Center)
        Text(PlayerManager.isFollowed(this.effectiveArtist(), this.followedArtistIds) ? 'Unfollow Artist' : 'Follow Artist')
          .fontSize(16)
          .fontColor(MeowColors.textPrimary)
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        PlayerManager.toggleFollowedInStorage(this.effectiveArtist(), this.followedArtistIds)
      })

      Row({ space: 18 }) {
        Text('↗')
          .fontSize(20)
          .fontColor(MeowColors.textSecondary)
          .width(28)
          .textAlign(TextAlign.Center)
        Text('Share Artist')
          .fontSize(16)
          .fontColor(MeowColors.textPrimary)
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        this.showMenuSheet = false
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 36 })
    .backgroundColor(MeowColors.solidSurface)
    .borderRadius({ topLeft: MeowRadius.bottomSheet, topRight: MeowRadius.bottomSheet, bottomLeft: 0, bottomRight: 0 })
    .border({ width: 1, color: MeowColors.borderSubtle })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [this.repTrack().accentSoft, 0.0],
            [MeowColors.navyMid, 0.44],
            [MeowColors.navyBottom, 1.0]
          ]
        })

      Scroll() {
        Column({ space: 4 }) {
          this.Header()
          this.ControlsRow()
          Column({ space: 14 }) {
            this.ReleaseBanner()
            this.Tabs()
            this.PopularList()
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .padding({ bottom: MeowSpacing.mainContentBottomPadding })
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .zIndex(1)

      MiniPlayer()
        .margin({
          left: 14,
          right: 14,
          bottom: MeowSpacing.bottomNavHeight + MeowSpacing.bottomNavBottomOffset + MeowSpacing.miniPlayerBottomMargin
        })
        .zIndex(20)
      BottomNavBar({ activeTab: '' })
        .zIndex(30)

      if (this.showMenuSheet) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.55)')
          .zIndex(18)
          .onClick(() => {
            this.showMenuSheet = false
          })
        Column() {
          this.ArtistMenuSheet()
        }
        .width('100%')
        .position({ x: 0, y: 0 })
        .markAnchor({ x: 0, y: 0 })
        .zIndex(19)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.End)
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MeowColors.navyDeep)
    .expandSafeArea([SafeAreaType.SYSTEM])
  }
}
