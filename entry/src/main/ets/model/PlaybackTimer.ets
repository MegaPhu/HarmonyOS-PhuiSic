import { AudioEngine } from './AudioEngine'

export class PlaybackTimer {
  private static started: boolean = false

  static start(): void {
    if (PlaybackTimer.started) {
      return
    }
    PlaybackTimer.started = true
    AudioEngine.startTracking()
  }

  static stop(): void {
    PlaybackTimer.started = false
    AudioEngine.stopTracking()
  }
}
