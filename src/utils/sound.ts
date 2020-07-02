import { Howl } from 'howler'
import vuex from '@/store'
import shortBreakSound from '../assets/music/short.mp3'
import longBreakSound from '../assets/music/long.mp3'

const howlPlay = (...src: string[]) => async () => {
  if (!vuex.state.sounds.ui) return
  const howlInstance = new Howl({
    src: src,
  })
  howlInstance.play()
  return new Promise((resolve) => {
    howlInstance.on('end', resolve)
  })
}

export const play = Object.freeze({
  sound: {
    short: howlPlay(shortBreakSound),

    long: howlPlay(longBreakSound),
  },
  // comment: {},
})
