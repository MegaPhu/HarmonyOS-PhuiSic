import router from '@ohos.router'
import { BottomNavBar } from '../../components/BottomNavBar'
import { MiniPlayer } from '../../components/MiniPlayer'
import { DEFAULT_TRACK, MUSIC_TRACKS, Track } from '../../model/MusicData'
import { PlayerManager } from '../../model/PlayerManager'
import { MeowColors, MeowRadius, MeowSpacing, MeowTypography } from '../../theme/theme'
import { AudioEngine } from '../../model/AudioEngine'

interface ProfileMenuEntry {
  id: number
  icon: string
  label: string
  hint: string
  accent: string
  dangerous: boolean
}

interface GenreEntry {
  name: string
  count: number
  color: string
}

interface ActivityEntry {
  icon: string
  text: string
  sub: string
  accent: string
}

const PROFILE_MENU_ITEMS: ProfileMenuEntry[] = [
  { id: 1,  icon: '◎', label: 'Account',           hint: 'Manage your account details',      accent: '#2FA7D6', dangerous: false },
  { id: 2,  icon: '↺', label: 'Listening History',  hint: 'See your full play history',       accent: '#2AB7A9', dangerous: false },
  { id: 3,  icon: '⬇', label: 'Downloaded Songs',   hint: 'Songs saved for offline play',     accent: '#3DB060', dangerous: false },
  { id: 4,  icon: '♥', label: 'Favorite Songs',     hint: 'Your liked songs library',         accent: '#D65ACF', dangerous: false },
  { id: 5,  icon: '◉', label: 'Favorite Artists',   hint: 'Artists you follow',               accent: '#F5D84A', dangerous: false },
  { id: 6,  icon: '⌁', label: 'Listening Stats',    hint: 'Weekly taste and listening time',  accent: '#F5D84A', dangerous: false },
  { id: 7,  icon: '⚙', label: 'App Settings',       hint: 'Playback, quality, and privacy',   accent: '#A3ADB8', dangerous: false },
  { id: 8,  icon: '✕', label: 'Log Out',            hint: 'Sign out of your account',         accent: '#E05555', dangerous: true  },
]

const AVATAR_COLORS: string[] = [
  '#FFD700', '#2FA7D6', '#3DB060', '#D65ACF', '#E05555', '#F5843C'
]

@Entry
@Component
struct Profile {
  @StorageLink('currentTrack') private currentTrack: Track = DEFAULT_TRACK
  @StorageLink('isPlaying') private isPlaying: boolean = false
  @StorageLink('mockUsername') private mockUsername: string = 'Phu'
  @StorageLink('likedTrackIds') private likedTrackIds: string = ''
  @StorageLink('followedArtistIds') private followedArtistIds: string = ''
  @StorageLink('profileAvatarAccent') private profileAvatarAccent: string = '#FFD700'
  @State private showEditSheet: boolean = false
  @State private editName: string = ''
  @State private editAvatarAccent: string = '#FFD700'

  // ─── Data helpers ───────────────────────────────────────────────────────

  private likedTracks(): Track[] {
    const result: Track[] = []
    for (let i = 0; i < MUSIC_TRACKS.length; i++) {
      if (PlayerManager.isLiked(MUSIC_TRACKS[i], this.likedTrackIds)) {
        result.push(MUSIC_TRACKS[i])
      }
    }
    return result
  }

  private likedCount(liked: Track[]): number {
    return liked.length
  }

  private followedArtistList(): string[] {
    if (this.followedArtistIds.length === 0) {
      return []
    }
    const parts = this.followedArtistIds.split('|')
    const result: string[] = []
    for (let i = 0; i < parts.length; i++) {
      const p = parts[i].trim()
      if (p.length > 0) {
        result.push(p)
      }
    }
    return result
  }

  private followedCount(): number {
    return this.followedArtistList().length
  }

  private displayName(): string {
    return this.mockUsername.length > 0 ? this.mockUsername : 'Phu'
  }

  private email(): string {
    return this.displayName().toLowerCase() + '@phui.music'
  }

  private trackForArtist(artist: string): Track {
    for (let i = 0; i < MUSIC_TRACKS.length; i++) {
      if (MUSIC_TRACKS[i].artist === artist) {
        return MUSIC_TRACKS[i]
      }
    }
    return DEFAULT_TRACK
  }

  private topArtists(liked: Track[]): string[] {
    const source = liked.length > 0 ? liked : MUSIC_TRACKS
    const seen: string[] = []
    for (let i = 0; i < source.length; i++) {
      const artist = source[i].artist
      if (seen.indexOf(artist) < 0) {
        seen.push(artist)
      }
    }
    return seen.slice(0, 6)
  }

  private genreEntries(): GenreEntry[] {
    const genres = ['Pop', 'Electronic', 'Phonk']
    const colors = ['#4A90D9', '#7B5EA7', '#E8844A']
    const entries: GenreEntry[] = []
    for (let gi = 0; gi < genres.length; gi++) {
      let count = 0
      for (let i = 0; i < MUSIC_TRACKS.length; i++) {
        if (MUSIC_TRACKS[i].genre === genres[gi]) {
          count++
        }
      }
      entries.push({ name: genres[gi], count: count, color: colors[gi] })
    }
    return entries
  }

  private genrePercent(count: number): number {
    if (MUSIC_TRACKS.length === 0) {
      return 0
    }
    return Math.round((count / MUSIC_TRACKS.length) * 100)
  }

  private activityEntries(liked: Track[]): ActivityEntry[] {
    const entries: ActivityEntry[] = []
    for (let i = 0; i < liked.length && i < 3; i++) {
      entries.push({
        icon: '♥',
        text: 'Liked \u201c' + liked[i].title + '\u201d',
        sub: liked[i].artist,
        accent: liked[i].accent
      })
    }
    const followed = this.followedArtistList()
    for (let i = 0; i < followed.length && i < 2; i++) {
      entries.push({
        icon: '◉',
        text: 'Followed ' + followed[i],
        sub: 'Artist',
        accent: '#FFD700'
      })
    }
    if (entries.length === 0) {
      entries.push({
        icon: '▶',
        text: 'Started exploring PhuiSic',
        sub: 'Jan 2026',
        accent: '#FFD700'
      })
    }
    return entries
  }

  // ─── Actions ────────────────────────────────────────────────────────────

  private async openArtist(artist: string): Promise<void> {
    const track = this.trackForArtist(artist)
    PlayerManager.playTrack(track)
    await router.pushUrl({ url: 'pages/main/ArtistSongs' })
  }

  private async logout(): Promise<void> {
    AudioEngine.pause()
    AppStorage.setOrCreate<boolean>('isLoggedIn', false)
    AppStorage.setOrCreate<string>('mockUsername', 'Phu')
    AppStorage.setOrCreate<string>('likedTrackIds', '')
    PlayerManager.reset()
    await router.replaceUrl({ url: 'pages/auth/Login' })
  }

  private confirmLogout(): void {
    AlertDialog.show({
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      autoCancel: true,
      primaryButton: {
        value: 'Cancel',
        action: () => {}
      },
      secondaryButton: {
        value: 'Log Out',
        fontColor: MeowColors.errorRed,
        action: () => {
          this.logout()
        }
      }
    })
  }

  private handleMenu(item: ProfileMenuEntry): void {
    if (item.dangerous) {
      this.confirmLogout()
      return
    }
    if (item.id === 1 || item.id === 7) {
      router.pushUrl({ url: 'pages/main/Premium' })
      return
    }
    if (item.id === 6) {
      router.pushUrl({ url: 'pages/main/Library', params: { tab: 'Playlist' } })
      return
    }
    if (item.id === 2 || item.id === 3 || item.id === 4) {
      router.pushUrl({ url: 'pages/main/Library', params: { tab: 'Playlist' } })
      return
    }
    if (item.id === 5) {
      router.pushUrl({ url: 'pages/main/Library', params: { tab: 'Artist' } })
      return
    }
    console.log('[Profile] menu: ' + item.label)
  }

  private openEditSheet(): void {
    this.editName = this.mockUsername
    this.editAvatarAccent = this.profileAvatarAccent
    this.showEditSheet = true
  }

  private saveProfile(): void {
    const trimmed = this.editName.trim()
    if (trimmed.length > 0) {
      this.mockUsername = trimmed
    }
    this.profileAvatarAccent = this.editAvatarAccent
    this.showEditSheet = false
  }

  // ─── Builders ───────────────────────────────────────────────────────────

  @Builder
  private Avatar(sz: number) {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(sz)
        .height(sz)
        .borderRadius(sz / 2)
        .backgroundColor(this.profileAvatarAccent)
        .shadow({ radius: 20, color: 'rgba(0,0,0,0.38)', offsetX: 0, offsetY: 4 })
      Text(this.displayName().charAt(0).toUpperCase())
        .fontSize(sz * 0.42)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.navyDeep)
        .textAlign(TextAlign.Center)
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor(MeowColors.solidSurface)
          .border({ width: 2, color: MeowColors.navyDeep })
        Text('✎')
          .fontSize(13)
          .fontColor(MeowColors.textPrimary)
      }
      .width(28)
      .height(28)
      .position({ x: sz - 32, y: sz - 32 })
      .hitTestBehavior(HitTestMode.None)
    }
    .width(sz)
    .height(sz)
  }

  @Builder
  private StatPill(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
      Text(label)
        .fontSize(11)
        .fontColor(MeowColors.textTertiary)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private ProfileHeader(liked: Track[]) {
    Column({ space: 0 }) {
      // ── Hero gradient zone ──
      Column({ space: 16 }) {
        // Avatar — tap to edit
        Row() {
          this.Avatar(92)
        }
        .hitTestBehavior(HitTestMode.Block)
        .onClick(() => {
          this.openEditSheet()
        })

        // Badge
        Text('Gold Member')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.goldBright)
          .padding({ left: 12, right: 12, top: 5, bottom: 5 })
          .borderRadius(12)
          .backgroundColor('rgba(255,215,0,0.12)')
          .border({ width: 1, color: 'rgba(255,215,0,0.28)' })

        // Name + email
        Column({ space: 6 }) {
          Text(this.displayName())
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.5)', offsetX: 0, offsetY: 2 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.email())
            .fontSize(13)
            .fontColor(MeowColors.textSecondary)
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 24, bottom: 20, left: 24, right: 24 })
      .linearGradient({
        angle: 180,
        colors: [
          [MeowColors.navyDeep, 0.0],
          [this.currentTrack.accentSoft, 0.28],
          [MeowColors.navyMid, 0.62],
          [MeowColors.navyDeep, 1.0]
        ]
      })

      // ── Stats row ──
      Row() {
        this.StatPill(this.likedCount(liked).toString(), 'Liked Songs')
        Column()
          .width(1)
          .height(28)
          .backgroundColor('rgba(255,255,255,0.10)')
        this.StatPill(this.followedCount().toString(), 'Following')
        Column()
          .width(1)
          .height(28)
          .backgroundColor('rgba(255,255,255,0.10)')
        this.StatPill('0', 'Followers')
      }
      .width('100%')
      .padding({ top: 16, bottom: 16, left: 8, right: 8 })
      .backgroundColor(MeowColors.solidSurface)
      .border({ width: { top: 1, bottom: 1 }, color: 'rgba(255,255,255,0.08)' })

    }
    .width('100%')
    .shadow({ radius: 20, color: MeowColors.shadowNavy, offsetX: 0, offsetY: 8 })
  }

  @Builder
  private TopArtistsSectionBody(topArtists: string[]) {
    Column({ space: 14 }) {
      Text('Top Artists')
        .fontSize(MeowTypography.subheadingSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')

      Scroll() {
        Row({ space: 18 }) {
          ForEach(topArtists, (artist: string) => {
            Column({ space: 10 }) {
              Image(this.trackForArtist(artist).artwork)
                .width(80)
                .height(80)
                .borderRadius(40)
                .objectFit(ImageFit.Cover)
                .clip(true)
                .border({ width: 2, color: 'rgba(255,255,255,0.14)' })
              Text(artist)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(MeowColors.textSecondary)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Center)
                .width(84)
            }
            .alignItems(HorizontalAlign.Center)
            .onClick(async () => {
              await this.openArtist(artist)
            })
          }, (artist: string) => artist)
        }
        .padding({ right: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .borderRadius(MeowRadius.large)
    .backgroundColor(MeowColors.solidSurface)
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
  }

  @Builder
  private TopArtistsSection(liked: Track[]) {
    this.TopArtistsSectionBody(this.topArtists(liked))
  }

  @Builder
  private GenreSection() {
    Column({ space: 16 }) {
      Text('Genre Mix')
        .fontSize(MeowTypography.subheadingSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')

      ForEach(this.genreEntries(), (entry: GenreEntry) => {
        Column({ space: 8 }) {
          Row() {
            Text(entry.name)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(MeowColors.textSecondary)
            Blank()
            Text(this.genrePercent(entry.count).toString() + '%')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(entry.color)
          }
          .width('100%')

          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(4)
              .borderRadius(3)
              .backgroundColor('rgba(255,255,255,0.08)')
            Row()
              .width(this.genrePercent(entry.count).toString() + '%')
              .height(4)
              .borderRadius(3)
              .linearGradient({
                angle: 90,
                colors: [
                  [entry.color, 0.0],
                  ['rgba(255,255,255,0.55)', 1.0]
                ]
              })
          }
          .width('100%')
          .height(4)
        }
        .width('100%')
      }, (entry: GenreEntry) => entry.name)
    }
    .width('100%')
    .padding(20)
    .borderRadius(MeowRadius.large)
    .backgroundColor(MeowColors.solidSurface)
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
  }

  @Builder
  private ActivitySectionBody(entries: ActivityEntry[]) {
    Column({ space: 14 }) {
      Text('Recent Activity')
        .fontSize(MeowTypography.subheadingSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')

      ForEach(entries, (entry: ActivityEntry, index: number) => {
        Row({ space: 14 }) {
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(42)
              .height(42)
              .borderRadius(21)
              .backgroundColor('rgba(255,255,255,0.06)')
              .border({ width: 1, color: 'rgba(255,255,255,0.10)' })
            Text(entry.icon)
              .fontSize(16)
              .fontColor(entry.accent)
          }
          .width(42)
          .height(42)

          Column({ space: 4 }) {
            Text(entry.text)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(MeowColors.textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(entry.sub)
              .fontSize(12)
              .fontColor(MeowColors.textTertiary)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height(56)
        .alignItems(VerticalAlign.Center)
      }, (entry: ActivityEntry, index: number) => index.toString() + entry.text)
    }
    .width('100%')
    .padding(20)
    .borderRadius(MeowRadius.large)
    .backgroundColor(MeowColors.solidSurface)
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
  }

  @Builder
  private ActivitySection(liked: Track[]) {
    this.ActivitySectionBody(this.activityEntries(liked))
  }

  @Builder
  private PlaylistsSection(liked: Track[]) {
    Column({ space: 14 }) {
      Text('Your Playlists')
        .fontSize(MeowTypography.subheadingSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')

      // ── Liked Songs card ──
      Row({ space: 14 }) {
        // Artwork: 2×2 collage or gold gradient fallback
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(64)
            .height(64)
            .borderRadius(10)
            .linearGradient({
              angle: 135,
              colors: [
                [MeowColors.goldDark, 0.0],
                [MeowColors.goldBright, 0.5],
                [MeowColors.goldDeep, 1.0]
              ]
            })
          Text('♥')
            .fontSize(28)
            .fontColor(MeowColors.navyDeep)
        }
        .width(64)
        .height(64)

        Column({ space: 5 }) {
          Text('Liked Songs')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.textPrimary)
          Text('Playlist · ' + this.likedCount(liked).toString() + ' songs')
            .fontSize(12)
            .fontColor(MeowColors.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('▶')
          .fontSize(MeowTypography.titleSize)
          .fontColor(MeowColors.goldBright)
      }
      .width('100%')
      .padding(14)
      .borderRadius(MeowRadius.control)
      .backgroundColor('rgba(255,255,255,0.05)')
      .border({ width: 1, color: 'rgba(255,215,0,0.16)' })
      .onClick(() => {
        console.log('[Profile] open liked songs')
      })

      // ── Secondary playlists row ──
      Row({ space: 14 }) {
        // Recently Played
        Column({ space: 10 }) {
          Image(this.currentTrack.artwork)
            .width('100%')
            .height(100)
            .borderRadius(MeowRadius.control)
            .objectFit(ImageFit.Cover)
            .clip(true)
            .backgroundColor(MeowColors.solidSurface)
          Column({ space: 3 }) {
            Text('Recently Played')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(MeowColors.textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text('Auto Playlist')
              .fontSize(11)
              .fontColor(MeowColors.textTertiary)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .onClick(() => {
          console.log('[Profile] open recently played')
        })

        // Downloaded
        Column({ space: 10 }) {
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width('100%')
              .height(100)
              .borderRadius(MeowRadius.control)
              .backgroundColor('rgba(42,183,169,0.14)')
              .border({ width: 1, color: 'rgba(42,183,169,0.20)' })
            Text('⬇')
              .fontSize(36)
              .fontColor('#2AB7A9')
          }
          Column({ space: 3 }) {
            Text('Downloaded')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(MeowColors.textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text('Offline Songs')
              .fontSize(11)
              .fontColor(MeowColors.textTertiary)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .onClick(() => {
          console.log('[Profile] open downloaded')
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(20)
    .borderRadius(MeowRadius.large)
    .backgroundColor(MeowColors.solidSurface)
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
  }

  @Builder
  private MenuSection() {
    Column({ space: 0 }) {
      ForEach(PROFILE_MENU_ITEMS, (item: ProfileMenuEntry) => {
        Row({ space: 14 }) {
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(42)
              .height(42)
              .borderRadius(21)
              .backgroundColor('rgba(255,255,255,0.05)')
              .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
            Circle()
              .width(22)
              .height(22)
              .fill(item.accent)
              .opacity(0.14)
            Text(item.icon)
              .fontSize(15)
              .fontColor(item.dangerous ? '#E05555' : item.accent)
          }
          .width(42)
          .height(42)
          .hitTestBehavior(HitTestMode.None)

          Column({ space: 3 }) {
            Text(item.label)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(item.dangerous ? '#E05555' : MeowColors.textPrimary)
              .maxLines(1)
            Text(item.hint)
              .fontSize(11)
              .fontColor(MeowColors.textTertiary)
              .maxLines(1)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .hitTestBehavior(HitTestMode.None)

          if (!item.dangerous) {
            Text('›')
              .fontSize(18)
              .fontColor(MeowColors.textTertiary)
          }
        }
        .width('100%')
        .height(64)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.handleMenu(item)
        })
      }, (item: ProfileMenuEntry) => item.id.toString())
    }
    .width('100%')
    .padding({ left: 18, right: 18 })
    .borderRadius(MeowRadius.large)
    .backgroundColor(MeowColors.solidSurface)
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
  }

  @Builder
  private EditProfileSheet() {
    Column({ space: 0 }) {
      Row() {
        Row()
          .width(36)
          .height(4)
          .borderRadius(2)
          .backgroundColor('rgba(255,255,255,0.28)')
      }
      .width('100%')
      .height(26)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Column({ space: 24 }) {
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(100)
            .height(100)
            .borderRadius(50)
            .backgroundColor(this.editAvatarAccent)
            .shadow({ radius: 24, color: 'rgba(0,0,0,0.4)', offsetX: 0, offsetY: 6 })
          Text(this.editName.trim().length > 0
            ? this.editName.trim().charAt(0).toUpperCase()
            : this.displayName().charAt(0).toUpperCase())
            .fontSize(42)
            .fontWeight(FontWeight.Bold)
            .fontColor(MeowColors.navyDeep)
            .textAlign(TextAlign.Center)
        }
        .width(100)
        .height(100)

        Column({ space: 10 }) {
          Text('Choose color')
            .fontSize(13)
            .fontColor(MeowColors.textTertiary)
            .width('100%')
            .textAlign(TextAlign.Start)

          Row({ space: 0 }) {
            ForEach(AVATAR_COLORS, (color: string) => {
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .backgroundColor(color)
                if (this.editAvatarAccent === color) {
                  Row()
                    .width(44)
                    .height(44)
                    .borderRadius(22)
                    .border({ width: 3, color: MeowColors.textPrimary })
                }
              }
              .layoutWeight(1)
              .height(44)
              .hitTestBehavior(HitTestMode.Block)
              .onClick(() => {
                this.editAvatarAccent = color
              })
            }, (color: string) => color)
          }
          .width('100%')
        }
        .width('100%')

        Column({ space: 8 }) {
          Text('Display name')
            .fontSize(13)
            .fontColor(MeowColors.textTertiary)
            .width('100%')
            .textAlign(TextAlign.Start)

          TextInput({ text: this.editName, placeholder: 'Enter your name' })
            .width('100%')
            .height(52)
            .fontSize(16)
            .fontColor(MeowColors.textPrimary)
            .placeholderColor(MeowColors.textTertiary)
            .backgroundColor('rgba(255,255,255,0.07)')
            .borderRadius(26)
            .border({ width: 1, color: 'rgba(255,255,255,0.14)' })
            .padding({ left: 20, right: 20 })
            .onChange((value: string) => {
              this.editName = value
            })
        }
        .width('100%')

        Row({ space: 12 }) {
          Row() {
            Text('Cancel')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(MeowColors.textSecondary)
          }
          .layoutWeight(1)
          .height(52)
          .borderRadius(26)
          .backgroundColor('rgba(255,255,255,0.07)')
          .border({ width: 1, color: 'rgba(255,255,255,0.12)' })
          .justifyContent(FlexAlign.Center)
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.showEditSheet = false
          })

          Row() {
            Text('Save')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(MeowColors.navyDeep)
          }
          .layoutWeight(1)
          .height(52)
          .borderRadius(26)
          .backgroundColor(MeowColors.goldBright)
          .justifyContent(FlexAlign.Center)
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.saveProfile()
          })
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 0, bottom: 48 })
    .backgroundColor(MeowColors.solidSurface)
    .borderRadius({ topLeft: 28, topRight: 28, bottomLeft: 0, bottomRight: 0 })
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
    .zIndex(21)
  }

  @Builder
  private BottomChrome() {
    Column() {
      MiniPlayer()
        .margin({ left: 14, right: 14, bottom: MeowSpacing.miniPlayerBottomMargin })
      BottomNavBar({ activeTab: 'Profile' })
    }
    .width('100%')
    .zIndex(10)
    .onClick(() => {})
  }

  @Builder
  private ProfileBody(liked: Track[]) {
    Column({ space: 0 }) {
      Text('Profile')
        .fontSize(MeowTypography.headingSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')
        .padding({ left: MeowSpacing.pagePadding, right: MeowSpacing.pagePadding, top: 56, bottom: 14 })

      this.ProfileHeader(liked)

      Column({ space: MeowSpacing.sectionGap }) {
        this.MenuSection()
      }
      .width('100%')
      .padding({
        left: MeowSpacing.pagePadding,
        right: MeowSpacing.pagePadding,
        top: MeowSpacing.sectionGap
      })
    }
    .width('100%')
    .padding({ bottom: MeowSpacing.mainContentBottomPadding + 24 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(MeowColors.navyDeep)

      Scroll() {
        this.ProfileBody(this.likedTracks())
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .zIndex(1)

      this.BottomChrome()

      if (this.showEditSheet) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.55)')
          .zIndex(20)
          .onClick(() => {
            this.showEditSheet = false
          })
        this.EditProfileSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MeowColors.navyDeep)
    .expandSafeArea([SafeAreaType.SYSTEM])
  }
}
