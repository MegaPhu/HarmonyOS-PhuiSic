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

  // Always return exactly 3 slots — previous / active / next — using empty
  // placeholders for out-of-range indices so the container height never jumps.
  private visibleLyrics(activeIndex: number): VisibleLyric[] {
    const lines: VisibleLyric[] = []
    for (let offset = -1; offset <= 1; offset++) {
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
    Column({ space: 8 }) {
      ForEach(this.visibleLyrics(activeIdx), (line: VisibleLyric) => {
        Text(line.text.length > 0 ? line.text : ' ')
          .fontSize(line.index === activeIdx ? 18 : 13)
          .fontWeight(line.index === activeIdx ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(line.index === activeIdx ? MeowColors.textPrimary : 'rgba(255,255,255,0.45)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .animation({ duration: 220, curve: Curve.EaseOut })
      }, (line: VisibleLyric) => `${this.track.id}-${line.index}`)
    }
    .width('100%')
    .height(82)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Text('Lyrics Preview')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.textPrimary)
        Blank()
        Text('Show')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.track.accent)
      }
      .width('100%')

      this.LyricLines(this.activeLyricIndex())
    }
    .width('100%')
    .padding(20)
    .borderRadius(MeowRadius.large)
    .backgroundColor(MeowColors.surfaceOverlay)
    .border({ width: 1, color: MeowColors.borderSoft })
    .shadow({
      radius: 20,
      color: MeowColors.shadowNavy,
      offsetX: 0,
      offsetY: 10
    })
    .animation({ duration: 220, curve: Curve.EaseOut })
    .onClick(() => {
      this.clickAction()
    })
  }
}
