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

  private visibleLyrics(activeIndex: number): VisibleLyric[] {
    const lines: VisibleLyric[] = []
    const startIndex = Math.max(0, activeIndex - 1)
    const endIndex = Math.min(this.track.lyrics.length - 1, activeIndex + 2)
    for (let i = startIndex; i <= endIndex; i++) {
      lines.push({ index: i, text: this.track.lyrics[i] })
    }
    return lines
  }

  private lineOpacity(index: number, activeIndex: number): number {
    const distance = Math.abs(index - activeIndex)
    if (distance === 0) {
      return 1
    }
    if (distance === 1) {
      return 0.52
    }
    return 0.32
  }

  @Builder
  private LyricLines(activeIdx: number) {
    Column({ space: 9 }) {
      ForEach(this.visibleLyrics(activeIdx), (line: VisibleLyric) => {
        Text(line.text.length > 0 ? line.text : ' ')
          .fontSize(line.index === activeIdx ? 19 : 14)
          .fontWeight(line.index === activeIdx ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(line.index === activeIdx ? MeowColors.textPrimary : MeowColors.textSecondary)
          .opacity(this.lineOpacity(line.index, activeIdx))
          .maxLines(line.index === activeIdx ? 2 : 1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }, (line: VisibleLyric) => `${this.track.id}-${line.index}`)
    }
    .width('100%')
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
    .animation({ duration: 250, curve: Curve.EaseOut })
    .onClick(() => {
      this.clickAction()
    })
  }
}
