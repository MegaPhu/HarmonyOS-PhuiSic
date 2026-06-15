import router from '@ohos.router'
import { GlassCard } from '../../components/GlassCard'
import { GlassInput } from '../../components/GlassInput'
import { PrimaryButton } from '../../components/PrimaryButton'
import { MeowColors, MeowSpacing, MeowTypography } from '../../theme/theme'

@Entry
@Component
struct SignUp {
  @State private fullName: string = ''
  @State private email: string = ''
  @State private password: string = ''
  @State private confirmPassword: string = ''
  @State private validationError: string = ''

  private async signUp(): Promise<void> {
    if (this.fullName.trim().length === 0 || this.email.trim().length === 0 ||
      this.password.length === 0) {
      this.validationError = 'Please fill in all fields.'
      return
    }
    if (this.password !== this.confirmPassword) {
      this.validationError = 'Passwords do not match.'
      return
    }
    this.validationError = ''
    console.log('[SignUpPage] demo sign up')
    AppStorage.setOrCreate<boolean>('isLoggedIn', true)
    AppStorage.setOrCreate<string>('mockUsername', this.fullName.trim())
    await router.replaceUrl({ url: 'pages/Index' })
  }

  private async navigateToLogin(): Promise<void> {
    console.log('[SignUpPage] navigate login')
    await router.replaceUrl({ url: 'pages/auth/Login' })
  }

  private goBack(): void {
    console.log('[SignUpPage] back')
    router.back()
  }

  build() {
    Stack() {
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
        Column({ space: 24 }) {
          Row() {
            Text('‹')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(MeowColors.textPrimary)
              .width(44)
              .height(44)
              .textAlign(TextAlign.Center)
              .borderRadius(22)
              .backgroundColor('rgba(255,255,255,0.06)')
              .onClick(() => {
                this.goBack()
              })
            Blank()
            Text('♫')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(MeowColors.goldBright)
              .opacity(0.86)
          }
          .width('100%')

          Column({ space: 8 }) {
            Text('premium listening starts quietly')
              .fontSize(13)
              .fontColor(MeowColors.textSecondary)
          }
          .alignItems(HorizontalAlign.Center)
          .width('100%')
          .padding({ top: 24 })

          GlassCard({ paddingValue: 26, radiusValue: 26 }) {
            Column({ space: MeowSpacing.fieldGap }) {
              Column({ space: 6 }) {
                Text('Create Account')
                  .fontSize(MeowTypography.headingSize)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MeowColors.textPrimary)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                Text('Join the PhuiSic community')
                  .fontSize(MeowTypography.bodySize)
                  .fontColor(MeowColors.textSecondary)
                  .textAlign(TextAlign.Center)
                  .width('100%')
              }

              GlassInput({
                value: $fullName,
                placeholder: 'Full Name',
                iconResource: $r('app.media.ic_full_name'),
                useIconImage: true
              })
              GlassInput({
                value: $email,
                placeholder: 'Email Address',
                iconResource: $r('app.media.ic_gmail'),
                useIconImage: true
              })
              GlassInput({
                value: $password,
                placeholder: 'Password',
                iconResource: $r('app.media.ic_password'),
                useIconImage: true,
                isPassword: true,
                showPasswordToggle: true
              })
              GlassInput({
                value: $confirmPassword,
                placeholder: 'Confirm Password',
                iconResource: $r('app.media.ic_password'),
                useIconImage: true,
                isPassword: true,
                showPasswordToggle: true
              })

              Text('By signing up, you agree to our Terms of use and Privacy Policy')
                .fontSize(MeowTypography.captionSize)
                .fontColor(MeowColors.textTertiary)
                .textAlign(TextAlign.Center)
                .width('100%')

              if (this.validationError.length > 0) {
                Text(this.validationError)
                  .fontSize(12)
                  .fontColor(MeowColors.errorRed)
                  .textAlign(TextAlign.Center)
                  .width('100%')
              }

              PrimaryButton({
                label: 'Sign Up',
                clickAction: () => {
                  this.signUp()
                }
              })

              Row() {
                Text('Already have an account? ')
                  .fontSize(13)
                  .fontColor(MeowColors.textSecondary)
                Text('Log In')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MeowColors.goldBright)
                  .onClick(() => {
                    this.navigateToLogin()
                  })
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
            }
          }
        }
        .width('100%')
        .padding({ left: MeowSpacing.pagePadding, right: MeowSpacing.pagePadding, top: 48, bottom: 48 })
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MeowColors.navyDeep)
    .expandSafeArea([SafeAreaType.SYSTEM])
  }
}
