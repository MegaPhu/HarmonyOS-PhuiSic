export class MeowColors {
  static readonly navyTop: ResourceColor = '#0d0d2b';
  static readonly navyMid: ResourceColor = '#10143A';
  static readonly navyBottom: ResourceColor = '#1a0a3d';
  static readonly navyDeep: ResourceColor = '#090A1C';
  static readonly navyButtonStart: ResourceColor = '#101027';
  static readonly navyButtonMid: ResourceColor = '#17172F';
  static readonly navyButtonEnd: ResourceColor = '#252545';

  static readonly goldDark: ResourceColor = '#B8860B';
  static readonly goldBright: ResourceColor = '#FFD700';
  static readonly goldSoft: ResourceColor = '#D4AF37';
  static readonly goldDeep: ResourceColor = '#8B6914';

  static readonly textPrimary: ResourceColor = '#FFFFFF';
  static readonly textSecondary: ResourceColor = 'rgba(255,255,255,0.70)';
  static readonly textSecondaryStrong: ResourceColor = 'rgba(255,255,255,0.75)';
  static readonly textTertiary: ResourceColor = 'rgba(255,255,255,0.40)';
  static readonly textQuaternary: ResourceColor = 'rgba(255,255,255,0.58)';
  static readonly textDisabled: ResourceColor = '#888888';
  static readonly textGold: ResourceColor = '#F4D77A';

  static readonly solidSurface: ResourceColor = '#1C1C3A';
  static readonly solidSurfaceRaised: ResourceColor = '#222244';
  static readonly solidSurfaceSoft: ResourceColor = 'rgba(28,28,58,0.86)';
  static readonly surfaceOverlay: ResourceColor = 'rgba(28,28,58,0.92)';
  static readonly navOverlay: ResourceColor = 'rgba(9,10,18,0.92)';
  static readonly navBarBg: ResourceColor = 'rgba(20,20,20,0.65)';
  static readonly miniPlayerOverlay: ResourceColor = 'rgba(12,13,31,0.92)';
  static readonly glassBg: ResourceColor = 'rgba(255,255,255,0.05)';
  static readonly glassInputBg: ResourceColor = 'rgba(255,255,255,0.065)';
  static readonly glassBgStrong: ResourceColor = 'rgba(255,255,255,0.08)';
  static readonly glassBgSoft: ResourceColor = 'rgba(255,255,255,0.035)';
  static readonly glassPanel: ResourceColor = 'rgba(12,13,31,0.58)';
  static readonly glassStroke: ResourceColor = 'rgba(255,215,0,0.42)';
  static readonly transparent: ResourceColor = 'rgba(0,0,0,0)';
  static readonly errorRed: ResourceColor = '#FF6B6B';

  static readonly borderSubtle: ResourceColor = 'rgba(255,255,255,0.075)';
  static readonly borderSoft: ResourceColor = 'rgba(255,255,255,0.09)';
  static readonly borderStrong: ResourceColor = 'rgba(255,255,255,0.10)';
  static readonly borderDisabled: ResourceColor = 'rgba(255,255,255,0.14)';
  static readonly borderGhost: ResourceColor = 'rgba(255,255,255,0.16)';

  static readonly glowGold: ResourceColor = 'rgba(212,175,55,0.40)';
  static readonly glowGoldSoft: ResourceColor = 'rgba(212,175,55,0.24)';
  static readonly glowGoldFaint: ResourceColor = 'rgba(212,175,55,0.22)';
  static readonly glowGoldHalo: ResourceColor = 'rgba(212,175,55,0.13)';
  static readonly goldRingSoft: ResourceColor = 'rgba(255,215,0,0.22)';
  static readonly shadowNavy: ResourceColor = 'rgba(4,5,20,0.48)';
  static readonly shadowPanel: ResourceColor = 'rgba(4,5,20,0.34)';
  static readonly shadowControl: ResourceColor = 'rgba(4,5,20,0.22)';
  static readonly shadowSubtle: ResourceColor = 'rgba(4,5,20,0.14)';
  static readonly shadowSoft: ResourceColor = 'rgba(0,0,0,0.40)';
  static readonly shadowMiniPlayer: ResourceColor = 'rgba(0,0,0,0.38)';
  static readonly shadowText: ResourceColor = 'rgba(0,0,0,0.28)';
  static readonly glassButtonBg: ResourceColor = 'rgba(255,255,255,0.07)';
  static readonly searchBarBg: ResourceColor = 'rgba(28,28,58,0.88)';
  static readonly gradientScrim: ResourceColor = 'rgba(9,10,28,0.84)';
}

export class MeowSpacing {
  static readonly xs: number = 6;
  static readonly sm: number = 8;
  static readonly md: number = 12;
  static readonly fieldGap: number = 16;
  static readonly cardPaddingSmall: number = 20;
  static readonly pagePadding: number = 24;
  static readonly cardPadding: number = 28;
  static readonly sectionGap: number = 28;
  static readonly sectionTitleGap: number = 16;
  static readonly sectionGapLarge: number = 32;
  static readonly bottomNavWidthPercent: string = '86%';
  static readonly bottomNavHeight: number = 60;
  static readonly bottomNavRadius: number = 30;
  static readonly bottomNavBottomOffset: number = 14;
  static readonly bottomNavMaskHeight: number = 116;
  static readonly tabItemWidth: number = 56;
  static readonly tabItemHeight: number = 50;
  static readonly tabActiveIconSize: number = 24;
  static readonly tabInactiveIconSize: number = 22;
  static readonly miniPlayerHeight: number = 76;
  static readonly miniPlayerBottomMargin: number = 10;
  static readonly bottomContentPaddingWithMiniPlayer: number = 180;
  static readonly bottomContentPaddingTabOnly: number = 116;
  static readonly mainContentBottomPadding: number = 180;
  static readonly playerContentBottomPadding: number = 80;
  static readonly iconGap: number = 5;
  static readonly rowGap: number = 14;
  static readonly tileGap: number = 18;
  static readonly headerPaddingTop: number = 56;
}

export class MeowRadius {
  static readonly chip: number = 8;
  static readonly control: number = 12;
  static readonly card: number = 20;
  static readonly large: number = 24;
  static readonly pill: number = 26;
  static readonly chipPill: number = 20;
  static readonly icon: number = 22;
  static readonly bottomSheet: number = 28;
}

export class MeowEffects {
  static readonly glowBlur: number = 12;
  static readonly backdropBlur: number = 20;
  static readonly cardShadowBlur: number = 30;
  static readonly cardShadowY: number = 12;
  static readonly pressScale: number = 0.97;
  static readonly cardShadowRadius: number = 16;
  static readonly cardShadowOffset: number = 7;
}

export class MeowPlayer {
  static readonly albumMinWidth: number = 220;
  static readonly albumMaxWidth: number = 360;
  static readonly albumWidthPercent: string = '90%';
  static readonly albumPausedScale: number = 1.0;
  static readonly albumPlayingScale: number = 1.04;
  static readonly albumZoomDuration: number = 240;

  static readonly addButtonSize: number = 44;
  static readonly addIconSize: number = 20;

  static readonly sideTap: number = 46;
  static readonly sideIcon: number = 27;
  static readonly skipTap: number = 50;
  static readonly skipIcon: number = 32;
  static readonly playTap: number = 60;
  static readonly playIcon: number = 30;
  static readonly pauseIcon: number = 26;

  static readonly secondaryTap: number = 44;
  static readonly secondaryIcon: number = 25;

  static readonly miniCardHeight: number = 76;
  static readonly miniCoverSize: number = 58;
  static readonly miniActionTap: number = 40;
  static readonly miniActionIcon: number = 23;
  static readonly miniPlayTap: number = 46;
  static readonly miniPlayIcon: number = 24;
}

export class MeowTypography {
  static readonly brandSize: number = 32;
  static readonly headingSize: number = 26;
  static readonly subheadingSize: number = 18;
  static readonly bodySize: number = 14;
  static readonly captionSize: number = 12;
  static readonly displaySize: number = 34;
  static readonly titleSize: number = 22;
  static readonly labelSize: number = 17;
  static readonly smallLabelSize: number = 13;
  static readonly tinySize: number = 11;

  static readonly brandWeight = FontWeight.Bolder;
  static readonly headingWeight = FontWeight.Bolder;
  static readonly subheadingWeight = FontWeight.Medium;
  static readonly bodyWeight = FontWeight.Regular;
}

export class MeowTheme {
  static readonly appName: string = 'PhuiSic';
  static readonly tagline: string = 'Discover the Purr-fect Rhythm';
}
