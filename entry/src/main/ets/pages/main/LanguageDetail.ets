import router from '@ohos.router'
import { BottomNavBar } from '../../components/BottomNavBar'
import { MiniPlayer } from '../../components/MiniPlayer'
import { MUSIC_TRACKS, Track } from '../../model/MusicData'
import { PlayerManager } from '../../model/PlayerManager'
import { MeowColors, MeowRadius, MeowSpacing, MeowTypography } from '../../theme/theme'

@Entry
@Component
struct LanguageDetail {
  @StorageLink('likedTrackIds') private likedTrackIds: string = ''
  @State private language: string = 'Thai'

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params['language'] && (params['language'] as string).length > 0) {
      this.language = params['language'] as string
    }
  }

  private gradientStart(): string {
    if (this.language === 'Thai') { return '#5C2F8A' }
    if (this.language === 'Chinese') { return '#1A5C8A' }
    if (this.language === 'English') { return '#1A6647' }
    if (this.language === 'Japanese') { return '#7A2030' }
    if (this.language === 'Spanish') { return '#8A4A1A' }
    if (this.language === 'Russian') { return '#2A4A8A' }
    return '#3A3A6A'
  }

  private gradientEnd(): string {
    if (this.language === 'Thai') { return '#9160D8' }
    if (this.language === 'Chinese') { return '#3DA0D8' }
    if (this.language === 'English') { return '#3AB07A' }
    if (this.language === 'Japanese') { return '#C45070' }
    if (this.language === 'Spanish') { return '#D87A3D' }
    if (this.language === 'Russian') { return '#5070D8' }
    return '#6A6AAA'
  }

  private langSubtitle(): string {
    if (this.language === 'Thai') { return 'เพลงไทย' }
    if (this.language === 'Chinese') { return '华语音乐' }
    if (this.language === 'English') { return 'English tracks' }
    if (this.language === 'Japanese') { return '日本の音楽' }
    if (this.language === 'Spanish') { return 'Música española' }
    if (this.language === 'Russian') { return 'Русская музыка' }
    return ''
  }

  private languageTracks(): Track[] {
    const lang = this.language
    return MUSIC_TRACKS.filter((t: Track): boolean => t.language === lang)
  }

  private contentBottomPadding(): number {
    return MeowSpacing.mainContentBottomPadding + 24
  }

  private async openTrack(track: Track): Promise<void> {
    PlayerManager.playTrack(track)
    const state = router.getState()
    if (state.name !== 'Player') {
      await router.pushUrl({ url: 'pages/main/Player' })
    }
  }

  @Builder
  private BackButton() {
    Text('‹')
      .fontSize(38)
      .fontWeight(FontWeight.Bold)
      .fontColor(MeowColors.textPrimary)
      .width(44)
      .height(44)
      .textAlign(TextAlign.Center)
      .borderRadius(22)
      .backgroundColor('rgba(0,0,0,0.35)')
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        router.back()
      })
  }

  @Builder
  private HeroHeader() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(220)
        .linearGradient({
          angle: 160,
          colors: [
            [this.gradientStart(), 0.0],
            [this.gradientEnd(), 0.55],
            [MeowColors.navyDeep, 1.0]
          ]
        })

      Column({ space: 0 }) {
        Row() {
          this.BackButton()
        }
        .width('100%')
        .padding({ top: 56, left: 20, right: 20 })

        Column({ space: 4 }) {
          Text(this.langSubtitle())
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.72)')
            .fontWeight(FontWeight.Medium)
          Text(this.language)
            .fontSize(48)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 24, right: 24, bottom: 24 })
      }
      .width('100%')
      .height(220)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(220)
  }

  @Builder
  private SectionTitle(title: string) {
    Text(title)
      .fontSize(MeowTypography.titleSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(MeowColors.textPrimary)
      .width('100%')
  }

  @Builder
  private PlaylistCard(track: Track) {
    Column({ space: 10 }) {
      Image(track.artwork)
        .width(158)
        .height(158)
        .objectFit(ImageFit.Cover)
        .borderRadius(MeowRadius.card)
        .clip(true)
        .backgroundColor(MeowColors.solidSurface)
        .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
        .shadow({
          radius: 18,
          color: MeowColors.shadowNavy,
          offsetX: 0,
          offsetY: 8
        })

      Column({ space: 3 }) {
        Text(track.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(158)
        Text(`${track.listeners} saves`)
          .fontSize(13)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(158)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width(158)
    .alignItems(HorizontalAlign.Start)
    .onClick(async () => {
      await this.openTrack(track)
    })
  }

  @Builder
  private TrackRow(track: Track) {
    Column() {
      Row({ space: 14 }) {
        Image(track.artwork)
          .width(58)
          .height(58)
          .objectFit(ImageFit.Cover)
          .borderRadius(MeowRadius.control)
          .clip(true)
          .backgroundColor(MeowColors.solidSurface)
          .flexShrink(0)
          .hitTestBehavior(HitTestMode.None)

        Column({ space: 4 }) {
          Text(track.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(track.artist)
            .fontSize(13)
            .fontColor(MeowColors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        .hitTestBehavior(HitTestMode.None)

        Stack({ alignContent: Alignment.Center }) {
          Text(PlayerManager.isLiked(track, this.likedTrackIds) ? '♥' : '♡')
            .fontSize(20)
            .fontColor(PlayerManager.isLiked(track, this.likedTrackIds)
              ? track.accent
              : MeowColors.textTertiary)
            .hitTestBehavior(HitTestMode.None)
        }
        .width(44)
        .height(44)
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => {
          PlayerManager.toggleLikedInStorage(track, this.likedTrackIds)
        })
      }
      .width('100%')
      .height(70)
      .padding({ left: 4, right: 4 })
      .alignItems(VerticalAlign.Center)

      Row()
        .width('100%')
        .height(1)
        .backgroundColor('rgba(255,255,255,0.06)')
        .margin({ left: 72 })
    }
    .width('100%')
    .onClick(async () => {
      await this.openTrack(track)
    })
  }

  @Builder
  private DiscoverSection(tracks: Track[]) {
    Column({ space: 16 }) {
      this.SectionTitle('Discover new music')
      Scroll() {
        Row({ space: 16 }) {
          ForEach(tracks, (track: Track) => {
            this.PlaylistCard(track)
          }, (track: Track) => `disc-${track.id}`)
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
  private TopTracksSection(tracks: Track[]) {
    Column({ space: 16 }) {
      this.SectionTitle('Popular')
      Column({ space: 0 }) {
        ForEach(tracks, (track: Track) => {
          this.TrackRow(track)
        }, (track: Track) => `tt-${track.id}`)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private EmptyState() {
    Column({ space: 12 }) {
      Text('♪')
        .fontSize(40)
        .fontColor(MeowColors.textTertiary)
      Text('No tracks available')
        .fontSize(MeowTypography.bodySize)
        .fontColor(MeowColors.textTertiary)
      Text('Explore other languages')
        .fontSize(MeowTypography.captionSize)
        .fontColor(MeowColors.textTertiary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 48, bottom: 48 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private PageBody() {
    Column({ space: MeowSpacing.sectionGap }) {
      this.HeroHeader()
      if (this.languageTracks().length === 0) {
        this.EmptyState()
      } else {
        Column({ space: MeowSpacing.sectionGap }) {
          this.DiscoverSection(this.languageTracks())
          this.TopTracksSection(this.languageTracks())
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
      }
    }
    .width('100%')
    .padding({ bottom: this.contentBottomPadding() })
  }

  @Builder
  private BottomChrome() {
    Column() {
      MiniPlayer()
        .margin({ left: 14, right: 14, bottom: MeowSpacing.miniPlayerBottomMargin })
      BottomNavBar({ activeTab: 'Search' })
    }
    .width('100%')
    .zIndex(10)
    .onClick(() => {})
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(MeowColors.navyDeep)

      Scroll() {
        this.PageBody()
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .zIndex(1)

      this.BottomChrome()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MeowColors.navyDeep)
    .expandSafeArea([SafeAreaType.SYSTEM])
  }
}
