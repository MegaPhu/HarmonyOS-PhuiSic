/**
 * Standard bottom-sheet drag handle. Single source of truth so every sheet
 * (Player Menu/Connect/Share/Queue, Edit Profile, Artist menu) uses an
 * identical handle bar. 40×4, pill radius, subtle white.
 */
@Component
export struct SheetHandle {
  build() {
    Row()
      .width(40)
      .height(4)
      .borderRadius(2)
      .backgroundColor('rgba(255,255,255,0.22)')
  }
}
