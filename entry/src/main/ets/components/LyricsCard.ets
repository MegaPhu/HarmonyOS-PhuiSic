import { DEFAULT_TRACK, Track } from '../model/MusicData'
import { MeowColors } from '../theme/theme'

@Preview
@Component
export struct LyricsCard {
  @StorageLink('currentTrack') track: Track = DEFAULT_TRACK
  @StorageLink('currentTimeSeconds') elapsedSeconds: number = 0
  clickAction: () => void = () => {}
  @State private showLyricsPressed: boolean = false

  // Indices of the sung (non-blank) lyric lines for the CURRENT track. Every
  // computation below derives from this and from this.track directly, so the
  // preview always reflects the current track and can never render a previous
  // track's lines after a rapid Next/Previous.
  private nonBlankIndices(): number[] {
    const res: number[] = []
    for (let i = 0; i < this.track.lyrics.length; i++) {
      if (this.track.lyrics[i].trim().length > 0) {
        res.push(i)
      }
    }
    return res
  }

  // Position of the active line within the non-blank list. ALWAYS clamped in
  // range, so a stale currentTimeSeconds during a rapid track change, or a
  // timestamps/lyrics count mismatch, can never point outside the current
  // track. Returns -1 only when the track genuinely has no lyrics.
  private activePosition(): number {
    const nb = this.nonBlankIndices()
    if (nb.length === 0) {
      return -1
    }
    if (this.track.timestamps.length === 0) {
      return 0
    }
    const elapsedMs = this.elapsedSeconds * 1000
    let tsIndex = 0
    for (let i = 0; i < this.track.timestamps.length; i++) {
      if (elapsedMs >= this.track.timestamps[i]) {
        tsIndex = i
      }
    }
    return Math.min(Math.max(tsIndex, 0), nb.length - 1)
  }

  @Builder
  private LyricLines() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.nonBlankIndices().length === 0) {
        Text('Lyrics unavailable')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(MeowColors.textSecondary)
          .width('100%')
      } else {
        // Karaoke float: every sung line occupies a fixed-height slot and the
        // whole column is translated so the active line sits at a fixed focal
        // slot. As the active position advances by one line, the translate
        // changes by one slot and the implicit animation slides every line
        // smoothly upward (old lines fade up and out, the next line floats in).
        Column() {
          ForEach(this.nonBlankIndices(), (idx: number, p: number) => {
            Text(this.track.lyrics[idx])
              .fontSize(p === this.activePosition() ? 26 : 20)
              .fontWeight(p === this.activePosition() ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(p === this.activePosition()
                ? MeowColors.textPrimary
                : 'rgba(255,255,255,0.60)')
              .opacity(p === this.activePosition() ? 1 : 0.9)
              .height(34)
              .lineHeight(34)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .animation({ duration: 240, curve: Curve.EaseOut })
          }, (idx: number) => `${this.track.id}-${idx}`)
        }
        .width('100%')
        // Pin the active line at focal slot 1, but never push the column down
        // past the top (clamp ≥ 0 distance) so there is no empty gap under the
        // header at the start of a song. Once the active line passes the focal
        // slot the column scrolls up and the active line stays pinned.
        .translate({ y: -Math.max(0, this.activePosition() - 1) * 34 })
        .animation({ duration: 240, curve: Curve.EaseOut })
      }
    }
    .width('100%')
    .layoutWeight(1)
    .clip(true)
  }

  build() {
    Column() {
      Text('Lyrics Preview')
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor(MeowColors.textPrimary)
        .width('100%')
        .margin({ bottom: 6 })

      this.LyricLines()

      Row() {
        Text('Show Lyrics')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(MeowColors.navyDeep)
      }
      .height(46)
      .padding({ left: 26, right: 26 })
      .borderRadius(23)
      .backgroundColor(MeowColors.textPrimary)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 14 })
      .scale({ x: this.showLyricsPressed ? 0.96 : 1, y: this.showLyricsPressed ? 0.96 : 1 })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .hitTestBehavior(HitTestMode.Block)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.showLyricsPressed = true
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.showLyricsPressed = false
        }
      })
      .onClick(() => {
        this.clickAction()
      })
    }
    .width('100%')
    .height(340)
    .alignItems(HorizontalAlign.Start)
    .padding(26)
    .borderRadius(28)
    .linearGradient({
      angle: 180,
      colors: [
        [this.track.accent, 0.0],
        [this.track.accentSoft, 1.0]
      ]
    })
    .border({ width: 1, color: MeowColors.borderStrong })
    .shadow({
      radius: 24,
      color: MeowColors.shadowNavy,
      offsetX: 0,
      offsetY: 12
    })
  }
}
