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
  mounted() {
    const setIgnoreMouseEvents = remote.getCurrentWindow().setIgnoreMouseEvents

    if (isProd) {
      addEventListener('pointerover', (event) => {
        this.canClick =
          event.target === document.documentElement
            ? this.canClick && setIgnoreMouseEvents(true, { forward: true })
            : this.canClick || setIgnoreMouseEvents(false) || true
      })

      setIgnoreMouseEvents(true, { forward: true })
    }
  },
})
