import { DEFAULT_TRACK, MUSIC_TRACKS, Track } from './MusicData'
import { AudioEngine } from './AudioEngine'

export class PlayerManager {
  static setCurrentTrack(track: Track, isPlaying: boolean): void {
    const currentTrackId = AppStorage.get<string>('currentTrackId')
    if (currentTrackId !== track.id) {
      AppStorage.setOrCreate<number>('currentTimeSeconds', 0)
    }
    AppStorage.setOrCreate<Track>('currentTrack', track)
    AppStorage.setOrCreate<string>('currentTrackId', track.id)
    AppStorage.setOrCreate<boolean>('isPlaying', isPlaying)
    if (isPlaying && AudioEngine.isReady()) {
      AudioEngine.loadAndPlay(track)
    } else if (!isPlaying) {
      AudioEngine.pause()
    }
  }

  static playTrack(track: Track): void {
    // Load the selected track paused — Player opens showing Play (▶);
    // user taps Play to start. Opening Player from the MiniPlayer of an
    // already-playing track keeps it playing (MiniPlayer does not call this).
    PlayerManager.setCurrentTrack(track, false)
  }

  static togglePlay(isPlaying: boolean): void {
    const newState = !isPlaying
    AppStorage.setOrCreate<boolean>('isPlaying', newState)
    if (newState && AudioEngine.isReady()) {
      AudioEngine.resume()
    } else if (!newState) {
      AudioEngine.pause()
    }
  }

  static pause(): void {
    AppStorage.setOrCreate<boolean>('isPlaying', false)
    AudioEngine.pause()
  }

  static reset(): void {
    AudioEngine.pause()
    AppStorage.setOrCreate<number>('currentTimeSeconds', 0)
    AppStorage.setOrCreate<Track>('currentTrack', DEFAULT_TRACK)
    AppStorage.setOrCreate<string>('currentTrackId', '')
    AppStorage.setOrCreate<boolean>('isPlaying', false)
  }

  static nextTrack(currentTrack: Track): Track {
    const currentIndex = MUSIC_TRACKS.findIndex((item: Track) => item.id === currentTrack.id)
    const safeIndex = currentIndex < 0 ? 0 : currentIndex
    const nextIndex = (safeIndex + 1) % MUSIC_TRACKS.length
    return MUSIC_TRACKS[nextIndex]
  }

  static shuffledNextTrack(currentTrack: Track): Track {
    const others = MUSIC_TRACKS.filter((item: Track): boolean => item.id !== currentTrack.id)
    if (others.length === 0) {
      return currentTrack
    }
    const idx = Math.floor(Math.random() * others.length)
    return others[idx]
  }

  static previousTrack(currentTrack: Track): Track {
    const currentIndex = MUSIC_TRACKS.findIndex((item: Track) => item.id === currentTrack.id)
    const safeIndex = currentIndex < 0 ? 0 : currentIndex
    const previousIndex = (safeIndex - 1 + MUSIC_TRACKS.length) % MUSIC_TRACKS.length
    return MUSIC_TRACKS[previousIndex]
  }

  static playNext(currentTrack: Track, isPlaying: boolean): void {
    PlayerManager.setCurrentTrack(PlayerManager.nextTrack(currentTrack), isPlaying)
  }

  static playPrevious(currentTrack: Track, isPlaying: boolean): void {
    PlayerManager.setCurrentTrack(PlayerManager.previousTrack(currentTrack), isPlaying)
  }

  static isLiked(track: Track, ids: string): boolean {
    const token = '|' + track.id + '|'
    return ids.indexOf(token) > -1
  }

  static toggleLiked(track: Track, ids: string): string {
    const token = '|' + track.id + '|'
    if (ids.indexOf(token) > -1) {
      return ids.replace(token, '')
    }
    return ids + token
  }

  static toggleLikedInStorage(track: Track, ids: string): void {
    AppStorage.setOrCreate<string>('likedTrackIds', PlayerManager.toggleLiked(track, ids))
  }

  static isFollowed(artist: string, ids: string): boolean {
    const token = '|' + artist + '|'
    return ids.indexOf(token) > -1
  }

  static toggleFollowed(artist: string, ids: string): string {
    const token = '|' + artist + '|'
    if (ids.indexOf(token) > -1) {
      return ids.replace(token, '')
    }
    return ids + token
  }

  static toggleFollowedInStorage(artist: string, ids: string): void {
    AppStorage.setOrCreate<string>('followedArtistIds',
      PlayerManager.toggleFollowed(artist, ids))
  }

}
