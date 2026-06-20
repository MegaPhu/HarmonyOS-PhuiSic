import router from '@ohos.router'
import { BottomNavBar } from '../../components/BottomNavBar'
import { MiniPlayer } from '../../components/MiniPlayer'
import { DEFAULT_TRACK, MUSIC_TRACKS, Track } from '../../model/MusicData'
import { PlayerManager } from '../../model/PlayerManager'
import { MeowColors, MeowRadius, MeowSpacing, MeowTypography } from '../../theme/theme'

@Entry
@Component
struct Library {
  @State private activeTab: string = 'Playlist'
  @StorageLink('likedTrackIds') likedTrackIds: string = ''
  @StorageLink('mockUsername') private username: string = 'Phu'
  @StorageLink('followedArtistIds') private followedArtistIds: string = ''

  aboutToAppear(): void {
    const p = router.getParams()
    if (p !== null && p !== undefined) {
      const params = p as Record<string, string>
      const tab = params['tab']
      if (tab === 'Playlist' || tab === 'Album' || tab === 'Artist') {
        this.activeTab = tab
      }
    }
  }

  private handleSearch(): void {
    console.log('[LibraryPage] search tapped')
    router.replaceUrl({ url: 'pages/main/Search' })
  }

  private handleAdd(): void {
    console.log('[LibraryPage] add — coming soon')
  }

  private async openTrack(track: Track): Promise<void> {
    console.log(`[LibraryPage] open ${track.title}`)
    PlayerManager.playTrack(track)
    const state = router.getState()
    if (state.name !== 'Player') {
      await router.pushUrl({ url: 'pages/main/Player' })
    }
  }

  private likedTracks(): Track[] {
    return MUSIC_TRACKS.filter((track: Track): boolean => PlayerManager.isLiked(track, this.likedTrackIds))
  }

  private likedPreviewTracks(liked: Track[]): Track[] {
    return liked.slice(0, 4)
  }

  private savedSongsLabel(count: number): string {
    return count === 1 ? '1 saved song' : `${count} saved songs`
  }

  private likedSongSummary(count: number): string {
    return `${this.savedSongsLabel(count)} · ${this.username}`
  }

  private trackById(id: string): Track {
    for (let i = 0; i < MUSIC_TRACKS.length; i++) {
      if (MUSIC_TRACKS[i].id === id) {
        return MUSIC_TRACKS[i]
      }
    }
    return DEFAULT_TRACK
  }

  private likedArtists(liked: Track[]): string[] {
    const tracks = liked
    const seen: string[] = []
    for (let i = 0; i < tracks.length; i++) {
      if (seen.indexOf(tracks[i].artist) < 0) {
        seen.push(tracks[i].artist)
      }
    }
    return seen
  }

  private combinedArtists(liked: Track[]): string[] {
    const artists: string[] = this.likedArtists(liked)
    if (this.followedArtistIds.length > 0) {
      const parts = this.followedArtistIds.split('|').filter((s: string): boolean => s.length > 0)
      for (let i = 0; i < parts.length; i++) {
        if (artists.indexOf(parts[i]) < 0) {
          artists.push(parts[i])
        }
      }
    }
    return artists
  }

  private artistAccent(name: string): string {
    const track = MUSIC_TRACKS.find((t: Track): boolean => t.artist === name)
    return track ? track.accent : '#888888'
  }

  private followedArtistCount(): number {
    if (this.followedArtistIds.length === 0) {
      return 0
    }
    return this.followedArtistIds.split('|').filter((s: string) => s.length > 0).length
  }

  @Builder
  private SearchGlyph() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(17)
        .height(17)
        .borderRadius(9)
        .border({ width: 2, color: MeowColors.textPrimary })
        .translate({ x: -2, y: -2 })
      Row()
        .width(9)
        .height(2)
        .borderRadius(1)
        .backgroundColor(MeowColors.textPrimary)
        .rotate({ angle: 45 })
        .translate({ x: 7, y: 8 })
    }
    .width(44)
    .height(44)
    .borderRadius(22)
    .backgroundColor('rgba(255,255,255,0.06)')
    .onClick(() => {
      this.handleSearch()
    })
  }

  @Builder
  private HeaderIcon(label: string, actionType: string) {
    Text(label)
      .fontSize(26)
      .fontWeight(FontWeight.Medium)
      .fontColor(MeowColors.textPrimary)
      .width(44)
      .height(44)
      .textAlign(TextAlign.Center)
      .borderRadius(22)
      .backgroundColor('rgba(255,255,255,0.06)')
      .onClick(() => {
        if (actionType === 'search') {
          this.handleSearch()
        } else {
          this.handleAdd()
        }
      })
  }

  @Builder
  private SectionHeader(title: string, subtitle: string = '') {
    Column({ space: 3 }) {
      Text(title)
        .fontSize(MeowTypography.subheadingSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')
      if (subtitle.length > 0) {
        Text(subtitle)
          .fontSize(MeowTypography.captionSize)
          .fontColor(MeowColors.textTertiary)
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private RecentHeader() {
    Row() {
      Row({ space: 6 }) {
        Text('↕')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .hitTestBehavior(HitTestMode.None)
        Text('Recently Played')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .hitTestBehavior(HitTestMode.None)
      }
      Blank()
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor('rgba(255,255,255,0.07)')
          .border({ width: 1, color: MeowColors.borderStrong })
          .hitTestBehavior(HitTestMode.None)
        Text('☰')
          .fontSize(16)
          .fontColor(MeowColors.textSecondary)
          .hitTestBehavior(HitTestMode.None)
      }
      .width(44)
      .height(44)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        console.log('[LibraryPage] sort tapped')
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private LibraryTab(label: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontWeight(this.activeTab === label ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(MeowColors.textPrimary)
    }
    .height(44)
    .padding({ left: 16, right: 16 })
    .borderRadius(MeowRadius.pill)
    .backgroundColor(this.activeTab === label ? 'rgba(255,255,255,0.18)' : MeowColors.glassButtonBg)
    .border({ width: 1, color: 'rgba(255,255,255,0.20)' })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.activeTab = label
    })
  }

  @Builder
  private LikedSongsBody(liked: Track[], previewTracks: Track[]) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(70)
          .height(70)
          .borderRadius(MeowRadius.card)
          .linearGradient({
            angle: 135,
            colors: [
              ['#1A0A3D', 0.0],
              ['#8B1A8B', 0.50],
              ['#00C4CC', 1.0]
            ]
          })
        if (previewTracks.length === 0) {
          Text('♥')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
        } else {
          Grid() {
            ForEach(previewTracks, (track: Track) => {
              GridItem() {
                Image(track.artwork)
                  .width(32)
                  .height(32)
                  .objectFit(ImageFit.Cover)
                  .clip(true)
              }
            }, (track: Track) => track.id)
          }
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .columnsGap(2)
          .rowsGap(2)
          .width(66)
          .height(66)
          .borderRadius(MeowRadius.card)
          .clip(true)
        }
      }
      .width(70)
      .height(70)

      Column({ space: 5 }) {
        Text('Liked Songs')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
        Text(this.likedSongSummary(liked.length))
          .fontSize(MeowTypography.bodySize)
          .fontColor(MeowColors.textSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 3 }) {
        Text('Pinned')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.goldBright)
        Text('♥')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(liked.length > 0 ? '#FF5555' : MeowColors.textTertiary)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(MeowColors.solidSurface)
    .border({ width: 1, color: MeowColors.borderSoft })
    .shadow({
      radius: 16,
      color: MeowColors.shadowNavy,
      offsetX: 0,
      offsetY: 6
    })
    .onClick(() => {
      if (liked.length > 0) {
        this.openTrack(liked[0])
      }
    })
  }

  @Builder
  private LikedSongs(liked: Track[]) {
    this.LikedSongsBody(liked, this.likedPreviewTracks(liked))
  }

  @Builder
  private LikedSongsGridItem(liked: Track[]) {
    Column({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width('100%')
          .aspectRatio(1)
          .borderRadius(20)
          .linearGradient({
            angle: 135,
            colors: [['#1A0A3D', 0.0], ['#8B1A8B', 0.50], ['#00C4CC', 1.0]]
          })
        if (liked.length > 0) {
          Grid() {
            ForEach(this.likedPreviewTracks(liked), (track: Track) => {
              GridItem() {
                Image(track.artwork)
                  .width('100%')
                  .height('100%')
                  .objectFit(ImageFit.Cover)
                  .clip(true)
              }
            }, (track: Track) => 'lp-' + track.id)
          }
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .columnsGap(2)
          .rowsGap(2)
          .width('100%')
          .aspectRatio(1)
          .borderRadius(20)
          .clip(true)
        } else {
          Text('♥')
            .fontSize(32)
            .fontColor(MeowColors.textPrimary)
        }
      }
      .width('100%')
      .aspectRatio(1)
      .shadow({ radius: 20, color: 'rgba(139,92,246,0.45)', offsetX: 0, offsetY: 8 })
      .border({ width: 1, color: 'rgba(255,255,255,0.14)' })

      Column({ space: 3 }) {
        Text('Liked Songs')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text('Playlist · ' + this.username)
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.65)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      if (liked.length > 0) {
        this.openTrack(liked[0])
      }
    })
  }

  @Builder
  private TrackGridItem(track: Track) {
    Column({ space: 8 }) {
      Image(track.artwork)
        .width('100%')
        .aspectRatio(1)
        .borderRadius(MeowRadius.control)
        .objectFit(ImageFit.Cover)
        .clip(true)
        .backgroundColor(MeowColors.solidSurface)
        .border({ width: 1, color: 'rgba(255,255,255,0.06)' })
      Column({ space: 2 }) {
        Text(track.title)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(track.artist)
          .fontSize(11)
          .fontColor(MeowColors.textTertiary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.openTrack(track)
    })
  }

  @Builder
  private CollectionCard(title: string, subtitle: string, marker: string,
                         accent: string, tabTarget: string = '', extraAction: () => void = () => {}) {
    Row({ space: 13 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(54)
          .height(54)
          .borderRadius(MeowRadius.card)
          .backgroundColor(accent)
          .opacity(0.82)
        Text(marker)
          .fontSize(MeowTypography.titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
      }
      .width(54)
      .height(54)

      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(subtitle)
          .fontSize(MeowTypography.captionSize)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .height(82)
    .padding({ left: 12, right: 12 })
    .borderRadius(MeowRadius.card)
    .backgroundColor(MeowColors.solidSurface)
    .border({ width: 1, color: MeowColors.borderSubtle })
    .onClick(() => {
      extraAction()
      if (tabTarget.length > 0) {
        this.activeTab = tabTarget
      }
    })
  }

  @Builder
  private CollectionGrid(liked: Track[]) {
    Column({ space: 12 }) {
      this.SectionHeader('Your Collection', 'Saved music organized for quick listening')
      Row({ space: 12 }) {
        this.CollectionCard('Liked Songs', this.likedSongSummary(liked.length), '♥', '#5B5EEB', '', () => {
          if (liked.length > 0) {
            this.openTrack(liked[0])
          }
        })
        this.CollectionCard('Daily Rotation', '4 playlists · updated', '♪', '#1B7D66')
      }
      .width('100%')
      Row({ space: 12 }) {
        this.CollectionCard('Albums', `${MUSIC_TRACKS.length} releases`, '▤', '#6B4FB8', 'Album')
        this.CollectionCard('Artists', `${this.followedArtistCount()} followed`, '◉', '#9B3F58', 'Artist')
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private PlaylistCard(track: Track, label: string, likedCount: number) {
    Row({ space: 14 }) {
      Image(track.artwork)
        .width(74)
        .height(74)
        .borderRadius(MeowRadius.card)
        .objectFit(ImageFit.Cover)
        .clip(true)
        .backgroundColor(MeowColors.solidSurface)
        .border({ width: 1, color: 'rgba(255,255,255,0.08)' })

      Column({ space: 5 }) {
        Text(label)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`Playlist · ${likedCount} songs`)
          .fontSize(MeowTypography.bodySize)
          .fontColor(MeowColors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(28)
        .fontColor(MeowColors.textTertiary)
    }
    .width('100%')
    .padding(12)
    .borderRadius(MeowRadius.card)
    .backgroundColor(MeowColors.solidSurface)
    .border({ width: 1, color: 'rgba(255,255,255,0.07)' })
    .onClick(() => {
      this.openTrack(track)
    })
  }

  @Builder
  private LibraryAlbumTile(track: Track) {
    Column({ space: 7 }) {
      Image(track.artwork)
        .width('100%')
        .aspectRatio(1)
        .borderRadius(MeowRadius.card)
        .objectFit(ImageFit.Cover)
        .clip(true)
        .backgroundColor(MeowColors.solidSurface)
        .border({ width: 1, color: 'rgba(255,255,255,0.08)' })

      Text(track.title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
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
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.openTrack(track)
    })
  }

  @Builder
  private AlbumGrid(liked: Track[]) {
    if (liked.length === 0) {
      Text('Like songs to build your album collection.')
        .fontSize(MeowTypography.bodySize)
        .fontColor(MeowColors.textTertiary)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 16, bottom: 16 })
    } else {
      Grid() {
        ForEach(liked, (track: Track) => {
          GridItem() {
            this.LibraryAlbumTile(track)
          }
        }, (track: Track) => `album-${track.id}`)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(16)
      .width('100%')
    }
  }

  @Builder
  private ArtistRow(name: string, hint: string, accent: string) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(62)
          .height(62)
          .fill(accent)
          .opacity(0.82)
        Text(name.substring(0, 1))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
      }
      .width(62)
      .height(62)
      .hitTestBehavior(HitTestMode.None)

      Column({ space: 5 }) {
        Text(name)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
        Text(hint)
          .fontSize(MeowTypography.bodySize)
          .fontColor(MeowColors.textSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        Text(PlayerManager.isFollowed(name, this.followedArtistIds) ? 'Following' : 'Follow')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(MeowColors.textPrimary)
      }
      .height(44)
      .padding({ left: 14, right: 14 })
      .borderRadius(22)
      .backgroundColor(PlayerManager.isFollowed(name, this.followedArtistIds)
        ? accent
        : MeowColors.transparent)
      .border({
        width: 1.5,
        color: PlayerManager.isFollowed(name, this.followedArtistIds)
          ? accent
          : 'rgba(255,255,255,0.40)'
      })
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        PlayerManager.toggleFollowedInStorage(name, this.followedArtistIds)
      })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .onClick(async () => {
      const track = MUSIC_TRACKS.find((t: Track): boolean => t.artist === name)
      if (track) {
        PlayerManager.playTrack(track)
        await router.pushUrl({ url: 'pages/main/ArtistSongs', params: { artist: name } })
      }
    })
  }

  @Builder
  private LikedTrackRow(track: Track) {
    Column() {
      Row({ space: 14 }) {
        Image(track.artwork)
          .width(56)
          .height(56)
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

        Column({ space: 4 }) {
          Text('♥')
            .fontSize(18)
            .fontColor(track.accent)
          Text(track.durationLabel)
            .fontSize(12)
            .fontColor(MeowColors.textTertiary)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .height(72)
      .padding({ left: 4, right: 4 })
      .alignItems(VerticalAlign.Center)

      Row()
        .width('100%')
        .height(1)
        .backgroundColor('rgba(255,255,255,0.06)')
        .margin({ left: 70 })
    }
    .width('100%')
    .onClick(() => {
      this.openTrack(track)
    })
  }

  @Builder
  private PlaylistContent(liked: Track[]) {
    Column({ space: 16 }) {
      this.RecentHeader()
      if (liked.length === 0) {
        Column({ space: 12 }) {
          Text('♥')
            .fontSize(36)
            .fontColor(MeowColors.textTertiary)
          Text('Like songs to build your playlist.')
            .fontSize(MeowTypography.bodySize)
            .fontColor(MeowColors.textTertiary)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ top: 32, bottom: 32 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Grid() {
          ForEach(liked, (track: Track) => {
            GridItem() {
              this.TrackGridItem(track)
            }
          }, (track: Track) => `pg-${track.id}`)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(10)
        .rowsGap(16)
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  private AlbumContent(liked: Track[]) {
    Column({ space: 16 }) {
      this.SectionHeader('Albums', 'Full releases and saved singles')
      this.AlbumGrid(liked)
    }
    .width('100%')
  }

  @Builder
  private ArtistContentBody(artists: string[]) {
    Column({ space: 16 }) {
      this.RecentHeader()
      if (artists.length === 0) {
        Column({ space: 10 }) {
          Text('◉')
            .fontSize(32)
            .fontColor(MeowColors.textTertiary)
          Text('Follow artists or like their songs to see them here.')
            .fontSize(MeowTypography.bodySize)
            .fontColor(MeowColors.textTertiary)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ top: 32, bottom: 32 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Column({ space: 2 }) {
          ForEach(artists, (name: string) => {
            this.ArtistRow(name, 'Artist', this.artistAccent(name))
          }, (name: string) => name)
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  private ArtistContent(liked: Track[]) {
    this.ArtistContentBody(this.combinedArtists(liked))
  }

  @Builder
  private LibraryHeader() {
    Row({ space: 10 }) {
      Text('Library')
        .fontSize(MeowTypography.headingSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .layoutWeight(1)
      this.SearchGlyph()
      this.HeaderIcon('+', 'add')
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private TabBar() {
    Row({ space: 10 }) {
      this.LibraryTab('Playlist')
      this.LibraryTab('Album')
      this.LibraryTab('Artist')
    }
    .width('100%')
  }

  @Builder
  private ActiveTabContent(liked: Track[]) {
    if (this.activeTab === 'Playlist') {
      this.PlaylistContent(liked)
    } else if (this.activeTab === 'Album') {
      this.AlbumContent(liked)
    } else {
      this.ArtistContent(liked)
    }
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
          this.LibraryHeader()
          this.TabBar()
          this.ActiveTabContent(this.likedTracks())
        }
        .width('100%')
        .padding({
          left: MeowSpacing.pagePadding,
          right: MeowSpacing.pagePadding,
          top: 64,
          bottom: MeowSpacing.bottomContentPaddingWithMiniPlayer
        })
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
      BottomNavBar({ activeTab: 'Library' })
        .zIndex(30)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MeowColors.navyDeep)
    .expandSafeArea([SafeAreaType.SYSTEM])
  }
}
