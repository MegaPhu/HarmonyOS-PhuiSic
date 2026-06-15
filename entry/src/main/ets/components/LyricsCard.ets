import { DEFAULT_TRACK, Track } from '../model/MusicData'
import { MeowColors, MeowRadius } from '../theme/theme'

interface VisibleLyric {
  index: number
  text: string
}

@Preview
@Component
export struct LyricsCard {
  @StorageLink('currentTrack') track: Track = DEFAULT_TRACK
  @StorageLink('currentTimeSeconds') elapsedSeconds: number = 0
  clickAction: () => void = () => {}

  // currentTimeSeconds (seconds) is the single source of truth; lyric
  // timestamps are milliseconds, so compare against elapsedSeconds * 1000.
  private activeLyricIndex(): number {
    if (this.track.lyrics.length === 0 || this.track.timestamps.length === 0) {
      return 0
    }
    let activeIndex = 0
    const elapsedMs = this.elapsedSeconds * 1000
    for (let i = 0; i < this.track.timestamps.length; i++) {
      if (elapsedMs >= this.track.timestamps[i]) {
        activeIndex = i
      }
    }
    return Math.min(activeIndex, this.track.lyrics.length - 1)
  }

  // 5 fixed slots centred on the active line; out-of-range -> blank placeholder
  // so the card height never jumps and lines never duplicate.
  private visibleLyrics(activeIndex: number): VisibleLyric[] {
    const lines: VisibleLyric[] = []
    for (let offset = -2; offset <= 2; offset++) {
      const i = activeIndex + offset
      if (i >= 0 && i < this.track.lyrics.length) {
        lines.push({ index: i, text: this.track.lyrics[i] })
      } else {
        lines.push({ index: i, text: '' })
      }
    }
    return lines
  }

  @Builder
  private LyricLines(activeIdx: number) {
    Column({ space: 20 }) {
      ForEach(this.visibleLyrics(activeIdx), (line: VisibleLyric) => {
        Text(line.text.length > 0 ? line.text : ' ')
          .fontSize(line.index === activeIdx ? 30 : 26)
          .fontWeight(line.index === activeIdx ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(line.index === activeIdx ? MeowColors.textPrimary : 'rgba(255,255,255,0.72)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .animation({ duration: 220, curve: Curve.EaseOut })
      }, (line: VisibleLyric) => `${this.track.id}-${line.index}`)
    }
    .width('100%')
    .height(212)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column({ space: 18 }) {
      Text('Lyrics Preview')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')

      this.LyricLines(this.activeLyricIndex())

      Row() {
        Text('Show Lyrics')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.navyDeep)
      }
      .height(46)
      .padding({ left: 26, right: 26 })
      .borderRadius(23)
      .backgroundColor(MeowColors.textPrimary)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        this.clickAction()
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(24)
    .borderRadius(MeowRadius.large)
    .linearGradient({
      angle: 160,
      colors: [
        [this.track.accent, 0.0],
        [this.track.accentSoft, 1.0]
      ]
    })
    .border({ width: 1, color: 'rgba(255,255,255,0.10)' })
    .shadow({
      radius: 20,
      color: MeowColors.shadowNavy,
      offsetX: 0,
      offsetY: 10
    })
  }
}
