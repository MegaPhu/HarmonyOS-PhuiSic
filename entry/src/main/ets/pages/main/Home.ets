import router from '@ohos.router'
import { BottomNavBar } from '../../components/BottomNavBar'
import { MiniPlayer } from '../../components/MiniPlayer'
import { DEFAULT_TRACK, MUSIC_CATEGORIES, MUSIC_TRACKS, MusicCategory, Track } from '../../model/MusicData'
import { PlayerManager } from '../../model/PlayerManager'
import { MeowColors, MeowRadius, MeowSpacing, MeowTypography } from '../../theme/theme'

@Entry
@Component
struct Home {
  @State private activeCategory: string = 'All'
  @StorageLink('currentTrack') private currentTrack: Track = DEFAULT_TRACK
  // Shared profile source of truth (same keys Profile.ets reads/writes) so the
  // header avatar + greeting stay in sync with the Profile page everywhere.
  @StorageLink('mockUsername') private mockUsername: string = 'Phu'
  @StorageLink('profileAvatarAccent') private profileAvatarAccent: string = '#FFD700'

  private async openTrack(track: Track): Promise<void> {
    console.log(`[HomePage] open ${track.title}`)
    PlayerManager.playTrack(track)
    const state = router.getState()
    if (state.name === 'Player') {
      return
    }
    await router.pushUrl({ url: 'pages/main/Player' })
  }

  // Derived from the shared profile keys — never hardcode name/avatar here.
  private displayName(): string {
    return this.mockUsername.length > 0 ? this.mockUsername : 'Phu'
  }

  private avatarInitial(): string {
    return this.displayName().charAt(0).toUpperCase()
  }

  private greetingText(): string {
    const hour = new Date().getHours()
    let base = 'Good evening'
    if (hour < 12) {
      base = 'Good morning'
    } else if (hour < 18) {
      base = 'Good afternoon'
    }
    return `${base}, ${this.displayName()}`
  }

  private visibleTracks(): Track[] {
    if (this.activeCategory === 'Thai') {
      return MUSIC_TRACKS.filter((t: Track) => t.language === 'Thai')
    }
    if (this.activeCategory === 'Japanese') {
      return MUSIC_TRACKS.filter((t: Track) => t.language === 'Japanese')
    }
    if (this.activeCategory === 'International') {
      return MUSIC_TRACKS.filter((t: Track) => t.language !== 'Thai' && t.language !== 'Japanese')
    }
    return MUSIC_TRACKS
  }

  private railTitle(): string {
    if (this.activeCategory === 'All') {
      return 'Today\'s Picks'
    }
    return `${this.activeCategory} Picks`
  }

  private secondaryRailTitle(): string {
    if (this.currentTrack.id !== DEFAULT_TRACK.id) {
      return `More Like ${this.currentTrack.artist}`
    }
    const tracks = this.visibleTracks()
    return tracks.length > 0 ? `More Like ${tracks[0].artist}` : 'More to Explore'
  }

  private contentBottomPadding(): number {
    return MeowSpacing.bottomContentPaddingWithMiniPlayer
  }

  @Builder
  private BrandBadge() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.profileAvatarAccent)
        .shadow({ radius: 16, color: 'rgba(0,0,0,0.32)', offsetX: 0, offsetY: 4 })
      Text(this.avatarInitial())
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.navyDeep)
    }
    .width(48)
    .height(48)
  }

  @Builder
  private Header() {
    Row({ space: 14 }) {
      this.BrandBadge()
      Column({ space: 3 }) {
        Text('PhuiSic')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.greetingText())
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private CategoryChip(category: MusicCategory) {
    Row() {
      Text(category.label)
        .fontSize(14)
        .fontWeight(this.activeCategory === category.label ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.activeCategory === category.label ? MeowColors.navyDeep : MeowColors.textPrimary)
    }
    .height(40)
    .padding({ left: 20, right: 20 })
    .borderRadius(MeowRadius.chipPill)
    .linearGradient({
      angle: 135,
      colors: this.activeCategory === category.label ? [
        [MeowColors.goldDark, 0.0],
        [MeowColors.goldBright, 0.36],
        [MeowColors.goldSoft, 0.72],
        [MeowColors.goldDeep, 1.0]
      ] : [
        [MeowColors.glassBg, 0.0],
        [MeowColors.glassBg, 1.0]
      ]
    })
    .border({ width: 1, color: this.activeCategory === category.label ? MeowColors.glassStroke : 'rgba(255,255,255,0.12)' })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      console.log(`[HomePage] category ${category.label}`)
      this.activeCategory = category.label
    })
  }

  @Builder
  private CategoryTabs() {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(MUSIC_CATEGORIES, (category: MusicCategory) => {
          this.CategoryChip(category)
        }, (category: MusicCategory) => category.id)
      }
      .padding({ right: 40 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  private SectionHeader(title: string, showAction: boolean = false) {
    Row() {
      Text(title)
        .fontSize(MeowTypography.titleSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .layoutWeight(1)
      if (showAction) {
        Text('Show all')
          .fontSize(MeowTypography.smallLabelSize)
          .fontWeight(FontWeight.Medium)
          .fontColor(MeowColors.goldBright)
          .padding({ left: 10, right: 2, top: 6, bottom: 6 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/main/Library' })
          })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private RecentSquareCard(track: Track) {
    Column({ space: 10 }) {
      Image(track.artwork)
        .width(136)
        .height(136)
        .objectFit(ImageFit.Cover)
        .borderRadius(MeowRadius.card)
        .clip(true)
        .backgroundColor(MeowColors.solidSurface)
        .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
        .shadow({
          radius: 14,
          color: MeowColors.shadowNavy,
          offsetX: 0,
          offsetY: 6
        })
      Text(track.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(MeowColors.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Text(track.artist)
        .fontSize(12)
        .fontColor(MeowColors.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width(136)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.openTrack(track)
    })
  }

  @Builder
  private RecentGrid() {
    Column({ space: MeowSpacing.sectionTitleGap }) {
      this.SectionHeader('Recently Played', true)
      Scroll() {
        Row({ space: 14 }) {
          ForEach(this.visibleTracks().slice(0, 6), (song: Track) => {
            this.RecentSquareCard(song)
          }, (song: Track) => 'recent-' + song.id)
        }
        .padding({ right: 40 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private KindBadge(kind: string) {
    Text(kind)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(MeowColors.textSecondary)
  }

  @Builder
  private PickCard(track: Track) {
    Column({ space: 10 }) {
      Image(track.artwork)
        .width(164)
        .height(164)
        .objectFit(ImageFit.Cover)
        .borderRadius(MeowRadius.card)
        .clip(true)
        .backgroundColor(MeowColors.solidSurface)
        .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
        .shadow({
          radius: 16,
          color: MeowColors.shadowNavy,
          offsetX: 0,
          offsetY: 7
        })

      Column({ space: 6 }) {
        Text(track.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(MeowColors.textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(track.artist)
          .fontSize(13)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width(164)
    .onClick(() => {
      this.openTrack(track)
    })
  }

  @Builder
  private HorizontalPicks(title: string, startIndex: number) {
    Column({ space: MeowSpacing.sectionTitleGap }) {
      this.SectionHeader(title)
      Scroll() {
        Row({ space: 14 }) {
          ForEach(this.visibleTracks().slice(startIndex, startIndex + 6), (song: Track) => {
            this.PickCard(song)
          }, (song: Track) => 'pick' + startIndex.toString() + '-' + song.id)
        }
        .padding({ right: 40 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private HomeContent() {
    Column({ space: MeowSpacing.sectionGap }) {
      this.Header()
      this.CategoryTabs()
      if (this.visibleTracks().length === 0) {
        Column({ space: 8 }) {
          Text('No tracks in this category')
            .fontSize(MeowTypography.bodySize)
            .fontColor(MeowColors.textTertiary)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        this.RecentGrid()
        this.HorizontalPicks(this.railTitle(), 0)
        this.HorizontalPicks(this.secondaryRailTitle(), 1)
      }
    }
    .width('100%')
    .padding({
      left: MeowSpacing.pagePadding,
      right: MeowSpacing.pagePadding,
      top: MeowSpacing.headerPaddingTop,
      bottom: this.contentBottomPadding()
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [MeowColors.navyTop, 0.0],
            [MeowColors.navyMid, 0.50],
            [MeowColors.navyBottom, 1.0]
          ]
        })

      Scroll() {
        this.HomeContent()
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .zIndex(0)

      MiniPlayer()
        .margin({
          left: 14,
          right: 14,
          bottom: MeowSpacing.bottomNavHeight + MeowSpacing.bottomNavBottomOffset + MeowSpacing.miniPlayerBottomMargin
        })
        .zIndex(20)
      BottomNavBar({ activeTab: 'Home' })
        .zIndex(30)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MeowColors.navyDeep)
    .expandSafeArea([SafeAreaType.SYSTEM])
  }
}
