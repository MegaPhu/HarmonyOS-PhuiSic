import { media } from '@kit.MediaKit'
import { common } from '@kit.AbilityKit'
import { DEFAULT_TRACK, MUSIC_TRACKS, Track } from './MusicData'

export class AudioEngine {
  private static avPlayer: media.AVPlayer | null = null
  private static context: common.UIAbilityContext | null = null
  private static positionTimer: number = -1
  private static tracking: boolean = false
  private static currentSrc: string = ''
  private static loading: boolean = false
  private static seekedTo: number = -1
  private static playStartTime: number = -1
  private static playStartSecs: number = 0

  static init(ctx: common.UIAbilityContext): void {
    AudioEngine.context = ctx
  }

  static isReady(): boolean {
    return AudioEngine.context !== null
  }

  // Public fire-and-forget — callers never await this
  static loadAndPlay(track: Track): void {
    AudioEngine.doLoadAndPlay(track).catch((e: Error): void => {
      console.error('[AudioEngine] loadAndPlay failed:', e.message)
    })
  }

  private static async doLoadAndPlay(track: Track): Promise<void> {
    if (AudioEngine.context === null) {
      return
    }
    if (AudioEngine.loading) {
      return
    }
    const ctx = AudioEngine.context

    // Same track already loaded and player exists — just resume from pause
    if (AudioEngine.currentSrc === track.audioSrc && AudioEngine.avPlayer !== null) {
      AudioEngine.avPlayer.play().catch((e: Error): void => {
        console.error('[AudioEngine] resume play error:', e.message)
      })
      if (AudioEngine.tracking) {
        AudioEngine.startPositionTimer()
      }
      return
    }

    AudioEngine.loading = true
    AudioEngine.currentSrc = track.audioSrc
    AudioEngine.stopPositionTimer()

    // Release existing player before creating a new one
    if (AudioEngine.avPlayer !== null) {
      const old = AudioEngine.avPlayer
      AudioEngine.avPlayer = null
      try {
        old.off('stateChange')
        await old.release()
      } catch (e) {
        console.error('[AudioEngine] release error:', JSON.stringify(e))
      }
    }

    // Create new AVPlayer and load the track
    try {
      const player = await media.createAVPlayer()
      AudioEngine.avPlayer = player

      player.on('stateChange', (state: media.AVPlayerState): void => {
        if (state === 'initialized') {
          // File source set — trigger prepare → prepared
          player.prepare().catch((e: Error): void => {
            console.error('[AudioEngine] prepare error:', e.message)
          })
        } else if (state === 'prepared') {
          // Buffering done — start playback
          player.play().catch((e: Error): void => {
            console.error('[AudioEngine] play error:', e.message)
          })
        } else if (state === 'playing') {
          AppStorage.setOrCreate<boolean>('isPlaying', true)
          if (AudioEngine.tracking) {
            AudioEngine.startPositionTimer()
          }
        } else if (state === 'paused') {
          AudioEngine.stopPositionTimer()
        } else if (state === 'completed') {
          AudioEngine.stopPositionTimer()
          AppStorage.setOrCreate<number>('currentTimeSeconds', 0)
          AudioEngine.handleCompletion()
        } else if (state === 'error') {
          AudioEngine.stopPositionTimer()
          AppStorage.setOrCreate<boolean>('isPlaying', false)
          AudioEngine.currentSrc = ''
          console.error('[AudioEngine] player entered error state')
        }
      })

      const rawFd = await ctx.resourceManager.getRawFd(track.audioSrc)
      if (rawFd.fd <= 0) {
        throw new Error(`Invalid fd for ${track.audioSrc}`)
      }
      player.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
      AudioEngine.loading = false
    } catch (e) {
      AudioEngine.loading = false
      AudioEngine.currentSrc = ''
      AppStorage.setOrCreate<boolean>('isPlaying', false)
      if (AudioEngine.avPlayer !== null) {
        const broken = AudioEngine.avPlayer
        AudioEngine.avPlayer = null
        try {
          broken.off('stateChange')
          await broken.release()
        } catch (releaseErr) {
          console.error('[AudioEngine] cleanup release error:', JSON.stringify(releaseErr))
        }
      }
      console.error('[AudioEngine] create/load error:', JSON.stringify(e))
    }
  }

  static pause(): void {
    AudioEngine.stopPositionTimer()
    if (AudioEngine.avPlayer !== null) {
      AudioEngine.avPlayer.pause().catch((e: Error): void => {
        console.error('[AudioEngine] pause error:', e.message)
      })
    }
  }

  static resume(): void {
    if (AudioEngine.avPlayer !== null) {
      AudioEngine.avPlayer.play().then((): void => {
        if (AudioEngine.tracking) {
          AudioEngine.startPositionTimer()
        }
      }).catch((e: Error): void => {
        console.error('[AudioEngine] resume error:', e.message)
      })
    } else {
      // No player exists — reload from AppStorage current track
      const track = AppStorage.get<Track>('currentTrack') ?? DEFAULT_TRACK
      if (track.audioSrc.length > 0) {
        AudioEngine.loadAndPlay(track)
      }
    }
  }

  static seekTo(seconds: number): void {
    AudioEngine.stopPositionTimer()
    AudioEngine.seekedTo = Math.max(0, Math.floor(seconds))
    AppStorage.setOrCreate<number>('currentTimeSeconds', seconds)
    if (AudioEngine.avPlayer !== null) {
      const player = AudioEngine.avPlayer
      try {
        const seekTimeoutId: number = setTimeout((): void => {
          if (AudioEngine.positionTimer < 0) {
            AudioEngine.tracking = true
            const playingNow: boolean = AppStorage.get<boolean>('isPlaying') ?? false
            if (playingNow) {
              AudioEngine.startPositionTimer()
            }
          }
        }, 2000)
        player.off('seekDone')
        player.on('seekDone', (seekDoneTime: number): void => {
          clearTimeout(seekTimeoutId)
          player.off('seekDone')
          const reportedSecs: number = Math.floor(seekDoneTime / 1000)
          const confirmed: number = reportedSecs > 0 ? reportedSecs : AudioEngine.seekedTo
          AppStorage.setOrCreate<number>('currentTimeSeconds', Math.max(0, confirmed))
          AudioEngine.tracking = true
          const isPlaying: boolean = AppStorage.get<boolean>('isPlaying') ?? false
          if (isPlaying) {
            AudioEngine.startPositionTimer()
          }
        })
        player.seek(Math.floor(seconds * 1000))
      } catch (e) {
        player.off('seekDone')
        AudioEngine.tracking = true
        const isPlaying: boolean = AppStorage.get<boolean>('isPlaying') ?? false
        if (isPlaying) {
          AudioEngine.startPositionTimer()
        }
        console.error('[AudioEngine] seek error:', JSON.stringify(e))
      }
    } else {
      AudioEngine.tracking = true
    }
  }

  // Call from PlaybackTimer.start() — enables position polling while visible
  static startTracking(): void {
    AudioEngine.tracking = true
    const isPlaying = AppStorage.get<boolean>('isPlaying') ?? false
    if (isPlaying && AudioEngine.avPlayer !== null) {
      AudioEngine.startPositionTimer()
    }
  }

  // Call from PlaybackTimer.stop() — stop polling; audio keeps playing in background
  static stopTracking(): void {
    AudioEngine.tracking = false
    AudioEngine.stopPositionTimer()
  }

  private static startPositionTimer(): void {
    if (AudioEngine.positionTimer !== -1) {
      return
    }
    let baseSecs: number = AppStorage.get<number>('currentTimeSeconds') ?? 0
    if (AudioEngine.avPlayer !== null) {
      const ms: number = AudioEngine.avPlayer.currentTime
      if (ms > 0) {
        baseSecs = Math.floor(ms / 1000)
        AppStorage.setOrCreate<number>('currentTimeSeconds', baseSecs)
      }
    }
    AudioEngine.playStartSecs = baseSecs
    AudioEngine.playStartTime = Date.now()
    AudioEngine.positionTimer = setInterval((): void => {
      if (AudioEngine.playStartTime < 0) {
        return
      }
      const elapsed: number = Math.floor((Date.now() - AudioEngine.playStartTime) / 1000)
      const newSecs: number = AudioEngine.playStartSecs + elapsed
      AppStorage.setOrCreate<number>('currentTimeSeconds', newSecs)
    }, 500)
  }

  private static stopPositionTimer(): void {
    if (AudioEngine.positionTimer !== -1) {
      clearInterval(AudioEngine.positionTimer)
      AudioEngine.positionTimer = -1
      AudioEngine.playStartTime = -1
    }
  }

  private static handleCompletion(): void {
    const track = AppStorage.get<Track>('currentTrack') ?? DEFAULT_TRACK
    const repeat = AppStorage.get<number>('repeatEnabled') ?? 0
    const shuffle = AppStorage.get<boolean>('shuffleEnabled') ?? false

    // Clear currentSrc so doLoadAndPlay always does a fresh load on track end
    AudioEngine.currentSrc = ''
    AppStorage.setOrCreate<number>('currentTimeSeconds', 0)

    let next: Track
    if (repeat === 2) {
      next = track
    } else if (shuffle) {
      const others = MUSIC_TRACKS.filter((t: Track): boolean => t.id !== track.id)
      next = others.length > 0 ? others[Math.floor(Math.random() * others.length)] : track
    } else {
      const idx = MUSIC_TRACKS.findIndex((t: Track): boolean => t.id === track.id)
      next = MUSIC_TRACKS[(idx < 0 ? 0 : idx + 1) % MUSIC_TRACKS.length]
    }

    AppStorage.setOrCreate<Track>('currentTrack', next)
    AppStorage.setOrCreate<string>('currentTrackId', next.id)
    AppStorage.setOrCreate<boolean>('isPlaying', true)
    AudioEngine.loadAndPlay(next)
  }
}
