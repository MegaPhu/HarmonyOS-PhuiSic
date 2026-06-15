import router from '@ohos.router'
import { BottomNavBar } from '../../components/BottomNavBar'
import { MiniPlayer } from '../../components/MiniPlayer'
import { MUSIC_TRACKS, Track } from '../../model/MusicData'
import { PlayerManager } from '../../model/PlayerManager'
import { MeowColors, MeowRadius, MeowSpacing, MeowTypography } from '../../theme/theme'

interface FilterCategory {
  id: string
  title: string
  subtitle: string
  start: ResourceColor
  end: ResourceColor
}

const LANGUAGE_CATEGORIES: FilterCategory[] = [
  { id: 'lang1', title: 'Thai', subtitle: 'เพลงไทย', start: '#5C2F8A', end: '#9160D8' },
  { id: 'lang2', title: 'Chinese', subtitle: '华语音乐', start: '#1A5C8A', end: '#3DA0D8' },
  { id: 'lang3', title: 'English', subtitle: 'English tracks', start: '#1A6647', end: '#3AB07A' },
  { id: 'lang4', title: 'Japanese', subtitle: '日本の音楽', start: '#7A2030', end: '#C45070' },
  { id: 'lang5', title: 'Spanish', subtitle: 'Música española', start: '#8A4A1A', end: '#D87A3D' },
  { id: 'lang6', title: 'Russian', subtitle: 'Русская музыка', start: '#2A4A8A', end: '#5070D8' },
]

const MOOD_CATEGORIES: FilterCategory[] = [
  { id: 'mood1', title: 'Romantic', subtitle: 'Love songs', start: '#7A2060', end: '#C45090' },
  { id: 'mood2', title: 'Sad', subtitle: 'Emotional', start: '#204A7A', end: '#4080C4' },
  { id: 'mood3', title: 'Chill', subtitle: 'Relax & unwind', start: '#1A5040', end: '#38908A' },
  { id: 'mood4', title: 'Electronic', subtitle: 'Beat & synth', start: '#1A1A4A', end: '#4040A0' },
]

@Entry
@Component
struct SearchPage {
  @StorageLink('searchQuery') query: string = ''
  @StorageLink('likedTrackIds') likedTrackIds: string = ''

  private matches(track: Track): boolean {
    if (this.query.length === 0) {
      return true
    }
    const q = this.query.toLowerCase()
    const searchable = [
      track.title,
      track.artist,
      track.album,
      track.language,
      track.genre,
      track.mood
    ].join(' ').toLowerCase()
    return searchable.includes(q)
  }

  private filteredTracks(): Track[] {
    const results: Track[] = []
    for (let i = 0; i < MUSIC_TRACKS.length; i++) {
      if (this.matches(MUSIC_TRACKS[i])) {
        results.push(MUSIC_TRACKS[i])
      }
    }
    return results
  }

  private resultSummary(count: number): string {
    if (this.query.length === 0) {
      return 'Songs you may want next'
    }
    if (count === 1) {
      return '1 match'
    }
    return `${count} matches`
  }

  private emptyResultsText(): string {
    if (this.query.length > 0) {
      return 'No matches for "' + this.query + '"'
    }
    return 'Try a song, artist, or album name.'
  }

  private contentBottomPadding(): number {
    return MeowSpacing.mainContentBottomPadding + 24
  }

  private clearQuery(): void {
    console.log('[SearchPage] clear query')
    this.query = ''
  }

  @Builder
  private SearchGlyph() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(17)
        .height(17)
        .borderRadius(9)
        .border({ width: 2, color: MeowColors.textSecondary })
        .translate({ x: -2, y: -2 })
      Row()
        .width(9)
        .height(2)
        .borderRadius(1)
        .backgroundColor(MeowColors.textSecondary)
        .rotate({ angle: 45 })
        .translate({ x: 7, y: 8 })
    }
    .width(28)
    .height(28)
  }

  @Builder
  private SearchBar() {
    Row({ space: 12 }) {
      this.SearchGlyph()

      TextInput({ placeholder: 'What do you want to listen to?', text: this.query })
        .height(50)
        .fontSize(16)
        .fontColor(MeowColors.textPrimary)
        .placeholderColor(MeowColors.textTertiary)
        .caretColor(MeowColors.goldBright)
        .backgroundColor('rgba(0,0,0,0)')
        .layoutWeight(1)
        .onChange((value: string) => {
          console.log('[SearchPage] query changed')
          this.query = value
        })

      if (this.query.length > 0) {
        Text('×')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textSecondary)
          .width(34)
          .height(34)
          .textAlign(TextAlign.Center)
          .borderRadius(17)
          .backgroundColor('rgba(255,255,255,0.06)')
          .onClick(() => {
            this.clearQuery()
          })
      }
    }
    .height(56)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .borderRadius(MeowRadius.control)
    .backgroundColor(MeowColors.searchBarBg)
    .border({ width: 1, color: this.query.length > 0 ? 'rgba(212,175,55,0.42)' : 'rgba(255,255,255,0.10)' })
    .shadow({
      radius: this.query.length > 0 ? 16 : 0,
      color: this.query.length > 0 ? 'rgba(212,175,55,0.14)' : 'rgba(0,0,0,0)',
      offsetX: 0,
      offsetY: 6
    })
    .animation({ duration: 180, curve: Curve.EaseOut })
  }

  @Builder
  private CategoryCard(category: FilterCategory) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Row()
        .width('100%')
        .height(150)
        .borderRadius(MeowRadius.card)
        .linearGradient({
          angle: 135,
          colors: [
            [category.start, 0.0],
            [category.end, 0.66],
            [MeowColors.surfaceOverlay, 1.0]
          ]
        })

      Column({ space: 6 }) {
        Text(category.title)
          .fontSize(MeowTypography.subheadingSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(category.subtitle)
          .fontSize(MeowTypography.captionSize)
          .fontColor('rgba(255,255,255,0.70)')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, bottom: 18 })

    }
    .layoutWeight(1)
    .height(150)
    .borderRadius(MeowRadius.card)
    .border({ width: 1, color: 'rgba(255,255,255,0.10)' })
    .clip(true)
    .shadow({
      radius: 10,
      color: 'rgba(4,5,20,0.32)',
      offsetX: 0,
      offsetY: 5
    })
    .onClick(async () => {
      if (category.id.startsWith('lang')) {
        await router.pushUrl({
          url: 'pages/main/LanguageDetail',
          params: { language: category.title }
        })
      } else {
        console.log(`[SearchPage] category ${category.title}`)
        this.query = category.title.toLowerCase()
      }
    })
  }

  @Builder
  private EmptyResults() {
    Column({ space: 10 }) {
      this.SearchGlyph()
      Text('No results found')
        .fontSize(MeowTypography.subheadingSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
      Text(this.emptyResultsText())
        .fontSize(MeowTypography.bodySize)
        .fontColor(MeowColors.textSecondary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 28, bottom: 28 })
    .borderRadius(MeowRadius.card)
    .backgroundColor('rgba(28,28,58,0.72)')
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private DiscoverCard(track: Track) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Image(track.artwork)
        .width(160)
        .height(160)
        .borderRadius(MeowRadius.card)
        .objectFit(ImageFit.Cover)
        .clip(true)
        .backgroundColor(MeowColors.solidSurface)
        .border({ width: 1, color: 'rgba(255,255,255,0.08)' })

      Row()
        .width(160)
        .height(104)
        .borderRadius(MeowRadius.card)
        .linearGradient({
          angle: 180,
          colors: [
            ['rgba(9,10,28,0)', 0.0],
            ['rgba(9,10,28,0.62)', 0.42],
            ['rgba(9,10,28,0.92)', 1.0]
          ]
        })

      Column({ space: 6 }) {
        Text(track.genre)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(MeowColors.textTertiary)
        Text(track.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(track.artist)
          .fontSize(12)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(160)
      .padding({ left: 14, right: 14, bottom: 14 })
      .alignItems(HorizontalAlign.Start)
    }
    .width(160)
    .height(160)
    .shadow({
      radius: 16,
      color: MeowColors.shadowNavy,
      offsetX: 0,
      offsetY: 7
    })
    .onClick(async () => {
      PlayerManager.playTrack(track)
      const state = router.getState()
      if (state.name !== 'Player') {
        await router.pushUrl({ url: 'pages/main/Player' })
      }
    })
  }

  @Builder
  private SearchResultRow(track: Track) {
    Column() {
      Row({ space: 14 }) {
        Image(track.artwork)
          .width(62)
          .height(62)
          .objectFit(ImageFit.Cover)
          .borderRadius(MeowRadius.control)
          .clip(true)
          .backgroundColor(MeowColors.solidSurface)
          .flexShrink(0)
          .hitTestBehavior(HitTestMode.None)

        Column({ space: 5 }) {
          Text(track.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('เพลง · ' + track.artist)
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
            .fontSize(22)
            .fontColor(PlayerManager.isLiked(track, this.likedTrackIds)
              ? track.accent
              : MeowColors.textSecondary)
            .textAlign(TextAlign.Center)
            .hitTestBehavior(HitTestMode.None)
        }
        .width(44)
        .height(44)
        .flexShrink(0)
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => {
          PlayerManager.toggleLikedInStorage(track, this.likedTrackIds)
        })
      }
      .width('100%')
      .height(72)
      .padding({ left: 4, right: 4 })
      .alignItems(VerticalAlign.Center)

      Row()
        .width('100%')
        .height(1)
        .backgroundColor('rgba(255,255,255,0.06)')
        .margin({ left: 76 })
    }
    .width('100%')
    .onClick(async () => {
      PlayerManager.playTrack(track)
      const state = router.getState()
      if (state.name !== 'Player') {
        await router.pushUrl({ url: 'pages/main/Player' })
      }
    })
  }

  @Builder
  private ResultsHeader(count: number) {
    Row() {
      Column({ space: 3 }) {
        Text(this.query.length > 0 ? 'Results' : 'Recommended Searches')
          .fontSize(MeowTypography.subheadingSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
        Text(this.resultSummary(count))
          .fontSize(MeowTypography.captionSize)
          .fontColor(MeowColors.textTertiary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private BrowseContent() {
    Column({ space: MeowSpacing.sectionGap }) {
      Column({ space: 16 }) {
        Text('Languages')
          .fontSize(MeowTypography.titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .width('100%')
        Row({ space: 14 }) {
          this.CategoryCard(LANGUAGE_CATEGORIES[0])
          this.CategoryCard(LANGUAGE_CATEGORIES[1])
        }
        .width('100%')
        Row({ space: 14 }) {
          this.CategoryCard(LANGUAGE_CATEGORIES[2])
          this.CategoryCard(LANGUAGE_CATEGORIES[3])
        }
        .width('100%')
        Row({ space: 14 }) {
          this.CategoryCard(LANGUAGE_CATEGORIES[4])
          this.CategoryCard(LANGUAGE_CATEGORIES[5])
        }
        .width('100%')
      }
      .width('100%')

      Column({ space: 16 }) {
        Text('Moods')
          .fontSize(MeowTypography.titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .width('100%')
        Row({ space: 14 }) {
          this.CategoryCard(MOOD_CATEGORIES[0])
          this.CategoryCard(MOOD_CATEGORIES[1])
        }
        .width('100%')
        Row({ space: 14 }) {
          this.CategoryCard(MOOD_CATEGORIES[2])
          this.CategoryCard(MOOD_CATEGORIES[3])
        }
        .width('100%')
      }
      .width('100%')

      Column({ space: 14 }) {
        Text('Discover')
          .fontSize(MeowTypography.titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .width('100%')
        Scroll() {
          Row({ space: 16 }) {
            ForEach(MUSIC_TRACKS, (track: Track) => {
              this.DiscoverCard(track)
            }, (track: Track) => `${track.id}`)
          }
          .padding({ right: 40 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private ResultsContentBody(results: Track[]) {
    Column({ space: 12 }) {
      this.ResultsHeader(results.length)
      if (results.length === 0) {
        this.EmptyResults()
      } else {
        ForEach(results.slice(0, this.query.length > 0 ? results.length : 4), (track: Track) => {
          this.SearchResultRow(track)
        }, (track: Track) => `search-${track.id}`)
      }
    }
    .width('100%')
  }

  @Builder
  private ResultsContent() {
    this.ResultsContentBody(this.filteredTracks())
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
        .linearGradient({
          angle: 180,
          colors: [
            [MeowColors.navyTop, 0.0],
            [MeowColors.navyMid, 0.52],
            [MeowColors.navyBottom, 1.0]
          ]
        })

      Scroll() {
        Column({ space: MeowSpacing.sectionGap }) {
          Row() {
            Text('Search')
              .fontSize(MeowTypography.headingSize)
              .fontWeight(FontWeight.Bold)
              .fontColor(MeowColors.textPrimary)
            Blank()
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          this.SearchBar()

          if (this.query.length === 0) {
            this.BrowseContent()
          }

          if (this.query.length > 0) {
            this.ResultsContent()
          }
        }
        .width('100%')
        .padding({ left: MeowSpacing.pagePadding, right: MeowSpacing.pagePadding, top: 64, bottom: MeowSpacing.mainContentBottomPadding + 24 })
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
