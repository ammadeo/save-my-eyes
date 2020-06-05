import { Howl } from 'howler'
import vuex from '@/store'
import shortBreakSound from '../assets/music/tone.mp3'

const howlShortBreak = new Howl({
  src: [shortBreakSound],
})

const howlPlay = (howlInstance: Howl) => async () => {
  if (!vuex.state.sounds.ui) return;

  howlInstance.play()
  return new Promise((resolve) => {
    howlInstance.on('end', resolve)
  })
}
export const play = Object.freeze({
  sound: {
    short: howlPlay(howlShortBreak),
    long: howlPlay(howlShortBreak), // temp
  },
  comment: {},
})
