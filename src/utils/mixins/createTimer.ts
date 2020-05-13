import vue from 'vue'
import anime from 'animejs'

export const CreateTimer = vue.extend({
  data() {
    return {
      anime: undefined,
      timePassedObj: { timePassed: 0 },
    } as {
      anime?: anime.AnimeInstance
      timePassedObj: { timePassed: number }
    }
  },
  methods: {
    createTimer(allTime: number, completeHandler: () => void) {
      const timePassedObj = this.timePassedObj
      return anime({
        targets: timePassedObj,
        timePassed: allTime,
        autoplay: true,
        duration: allTime,
        easing: 'linear',
        round: 10,
        complete: completeHandler,
      })
    },
  },
})
