import vue from 'vue'
import { remote } from 'electron'
import { isProd } from '@/background/env'

export const TransparentClickEngine = vue.extend({
  data() {
    return {
      canClick: false,
    } as {
      canClick: boolean | void
    }
  },
  beforeMount() {
    if (isProd) {
      const setIgnoreMouseEvents = remote.getCurrentWindow()
        .setIgnoreMouseEvents
      addEventListener('pointerover', (event) => {
        this.canClick =
          event.target === document.documentElement
            ? this.canClick && setIgnoreMouseEvents(true, { forward: true })
            : this.canClick || setIgnoreMouseEvents(false) || true
      })

      setIgnoreMouseEvents(false)
      setTimeout(() => {
        setIgnoreMouseEvents(true, { forward: true })
      }, 1)
    }
  },
  beforeDestroy() {
    const setIgnoreMouseEvents = remote.getCurrentWindow().setIgnoreMouseEvents
    setIgnoreMouseEvents(false)
  },
})
