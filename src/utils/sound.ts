import { Howl } from 'howler'
import vuex from '@/store'
import shortBreakStartSound from '../assets/music/shortStart.mp3'
import shortBreakEndSound from '../assets/music/shortEnd.mp3'
import longBreakStartSound from '../assets/music/longStart.mp3'
import longBreakEndSound from '../assets/music/longEnd.mp3'

const howlPlay = (...src: string[]) => async () => {
  if (!vuex.state.sounds.ui) return
  const howlInstance = new Howl({
    src: src
  })
  howlInstance.play()
  return new Promise((resolve) => {
    howlInstance.on('end', resolve)
  })
}

export const play = Object.freeze({
  sound: {
    short: {
      start: howlPlay(shortBreakStartSound),
      end: howlPlay(shortBreakEndSound),
    },
    long: {
      start: howlPlay(longBreakStartSound),
      end: howlPlay(longBreakEndSound),
    },
  },
  // comment: {},
})
