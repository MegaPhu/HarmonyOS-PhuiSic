import { DEFAULT_TRACK, Track } from '../model/MusicData'
import { MainNavigation } from '../model/MainNavigation'
import { MeowColors, MeowEffects } from '../theme/theme'

@Preview
@Component
export struct BottomNavBar {
  @Prop activeTab: string = 'Home'
  @StorageLink('currentTrack') private currentTrack: Track = DEFAULT_TRACK
  @State private pressedTab: string = ''

  private async navigate(tab: string): Promise<void> {
    if (tab === this.activeTab) {
      return
    }
    console.log(`[BottomNavBar] navigate ${tab}`)
    await MainNavigation.navigateTo(tab, this.activeTab)
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
    Column({ space: 5 }) {
      Text(this.iconFor(label))
        .fontSize(this.activeTab === label ? 26 : 22)
        .fontWeight(this.activeTab === label ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.activeTab === label ? MeowColors.textPrimary : MeowColors.textDisabled)
        .opacity(this.activeTab === label ? 1.0 : 0.55)
        .animation({ duration: 180, curve: Curve.EaseOut })
      Text(label)
        .fontSize(11)
        .fontWeight(this.activeTab === label ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.activeTab === label ? MeowColors.textPrimary : MeowColors.textDisabled)
        .opacity(this.activeTab === label ? 1.0 : 0.55)
        .maxLines(1)
        .animation({ duration: 180, curve: Curve.EaseOut })
    }
    .layoutWeight(1)
    .height(58)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .scale({
      x: this.pressedTab === label ? MeowEffects.pressScale : 1,
      y: this.pressedTab === label ? MeowEffects.pressScale : 1
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedTab = label
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedTab = ''
      }
    })
    .onClick(() => {
      this.navigate(label)
    })
  }

  build() {
    Row() {
      this.NavItem('Home')
      this.NavItem('Search')
      this.NavItem('Library')
      this.NavItem('Profile')
    }
    .width('100%')
    .height(58)
    .backgroundColor(MeowColors.navyDeep)
    .border({ width: 0.5, color: MeowColors.borderSoft, style: BorderStyle.Solid })
    .padding({ bottom: 8 })
  }
}
