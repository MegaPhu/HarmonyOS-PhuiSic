import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DEFAULT_TRACK, Track } from '../model/MusicData';
import { PlaybackTimer } from '../model/PlaybackTimer';
import { AudioEngine } from '../model/AudioEngine';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.initializeAppStorage();
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  private initializeAppStorage(): void {
    PersistentStorage.persistProp<boolean>('isLoggedIn', false);
    PersistentStorage.persistProp<string>('mockUsername', 'Phu');
    PersistentStorage.persistProp<string>('likedTrackIds', '');
    AppStorage.setOrCreate<boolean>('isPlaying', false);
    AppStorage.setOrCreate<Track>('currentTrack', DEFAULT_TRACK);
    AppStorage.setOrCreate<string>('currentTrackId', '');
    AppStorage.setOrCreate<number>('currentTimeSeconds', 0);
    AppStorage.setOrCreate<string>('searchQuery', '');
    PersistentStorage.persistProp<string>('followedArtistIds', '');
    AppStorage.setOrCreate<boolean>('shuffleEnabled', false);
    AppStorage.setOrCreate<number>('repeatEnabled', 0);
    PersistentStorage.persistProp<string>('profileAvatarAccent', '#FFD700');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // Init audio engine before loading content so PlayerManager can use it
    AudioEngine.init(this.context);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', '%{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    PlaybackTimer.start();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    PlaybackTimer.stop();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
