import { DEFAULT_TRACK, Track } from '../model/MusicData'
import { MainNavigation } from '../model/MainNavigation'
import { MeowColors, MeowEffects, MeowSpacing } from '../theme/theme'

@Preview
@Component
export struct BottomNavBar {
  @Prop activeTab: string = 'Home'
  @StorageLink('currentTrack') private currentTrack: Track = DEFAULT_TRACK
  @State private pressedTab: string = ''
  @State private navigatingTab: string = ''

  private async navigate(tab: string): Promise<void> {
    if (tab === this.activeTab || tab === this.navigatingTab) {
      return
    }
    this.navigatingTab = tab
    console.log(`[BottomNavBar] navigate ${tab}`)
    try {
      await MainNavigation.navigateTo(tab, this.activeTab)
    } finally {
      this.navigatingTab = ''
    }
  }

  private iconFor(label: string): string {
    if (label === 'Home') {
      return '⌂'
    }
    if (label === 'Search') {
      return '⌕'
    }
    if (label === 'Library') {
      return '▥'
    }
    return '◉'
  }

  @Builder
  private NavItem(label: string) {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 4 }) {
        // Icon only (no label). Fixed icon-box height keeps every tab aligned.
        // Active icon uses the current track's accent; inactive is dim white.
        Text(this.iconFor(label))
          .fontSize(this.activeTab === label ? MeowSpacing.tabActiveIconSize : MeowSpacing.tabInactiveIconSize)
          .fontWeight(this.activeTab === label ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.activeTab === label ? this.currentTrack.accent : 'rgba(255,255,255,0.72)')
          .opacity(this.activeTab === label ? 1 : 0.72)
          .height(30)
          .textAlign(TextAlign.Center)
          .hitTestBehavior(HitTestMode.None)
          .animation({ duration: 180, curve: Curve.EaseOut })
        // Active indicator dot (currentAccent). Always present but transparent
        // when inactive, so every tab keeps an identical height.
        Row()
          .width(this.activeTab === label ? 5 : 4)
          .height(this.activeTab === label ? 5 : 4)
          .borderRadius(2.5)
          .backgroundColor(this.activeTab === label ? this.currentTrack.accent : MeowColors.transparent)
          .hitTestBehavior(HitTestMode.None)
          .animation({ duration: 180, curve: Curve.EaseOut })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)

      Row()
        .width('100%')
        .height('100%')
        .borderRadius(25)
        .backgroundColor(this.pressedTab === label ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.001)')
        .hitTestBehavior(HitTestMode.Block)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.pressedTab = label
          } else if (event.type === TouchType.Up) {
            this.pressedTab = ''
            this.navigate(label)
          } else if (event.type === TouchType.Cancel) {
            this.pressedTab = ''
          }
        })
        .onClick(() => {
          this.navigate(label)
        })
    }
    .width(MeowSpacing.tabItemWidth)
    .height(MeowSpacing.tabItemHeight)
    .borderRadius(25)
    .scale({
      x: this.pressedTab === label ? MeowEffects.pressScale : 1,
      y: this.pressedTab === label ? MeowEffects.pressScale : 1
    })
    .animation({ duration: 130, curve: Curve.EaseOut })
  }

  build() {
    // The dark mask hides scroll content passing under the floating pill, while
    // the actual tab hit plates remain the only interactive children.
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height(MeowSpacing.bottomNavMaskHeight)
        .linearGradient({
          angle: 180,
          colors: [
            ['rgba(9,10,28,0.00)', 0.0],
            ['rgba(9,10,28,0.70)', 0.42],
            ['rgba(9,10,28,0.96)', 1.0]
          ]
        })
        .hitTestBehavior(HitTestMode.None)

      Row() {
        Row() {
          this.NavItem('Home')
          this.NavItem('Search')
          this.NavItem('Library')
          this.NavItem('Profile')
        }
        .width(MeowSpacing.bottomNavWidthPercent)
        .height(MeowSpacing.bottomNavHeight)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceAround)
        // Subtle dark glass — light enough not to feel heavy, opaque enough that
        // colourful page content does not bleed through unevenly.
        .backgroundColor('rgba(8,10,24,0.94)')
        .borderRadius(MeowSpacing.bottomNavRadius)
        .border({ width: 1, color: 'rgba(255,255,255,0.10)' })
        .backdropBlur(MeowEffects.backdropBlur)
        .clip(true)
        .shadow({
          radius: 16,
          color: 'rgba(0,0,0,0.30)',
          offsetX: 0,
          offsetY: 6
        })
      }
      .width('100%')
      .height(MeowSpacing.bottomNavHeight + MeowSpacing.bottomNavBottomOffset)
      .alignItems(VerticalAlign.Bottom)
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: MeowSpacing.bottomNavBottomOffset })
    }
    .width('100%')
    .height(MeowSpacing.bottomNavMaskHeight)
    .hitTestBehavior(HitTestMode.Transparent)
    .zIndex(30)
  }
}
