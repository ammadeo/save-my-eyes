<template>
  <div
    class="flex flex-col items-end justify-end p-16 overflow-hidden min-h-screen"
  >
    <div>
      <transition name="slide" appear>
        <BaseCard class="pointer-events-auto">
          <ContentBeforeBreak @run="run($event)" />
        </BaseCard>
      </transition>
    </div>
  </div>
</template>

<script lang="ts">
import ContentBeforeBreak from '../components/ContentBeforeBreak.vue'
import BaseCard from '../components/BaseCard.vue'
import { RunKey } from '@/types/menu'
import { remote } from 'electron'
import Vue from 'vue'
import { isProd } from '@/background/env'
import { rendererSetNextBreak as setNextBreak } from '@/background/ipc'

interface MousePolicy {
  _canClic: string
  (this: Window, event: PointerEvent): void
}

type Keys = 'menu' | 'settings' | 'stop-protection'
interface Data {
  openedKeys: Keys[]
  canClick: boolean | void
}

export default Vue.extend({
  components: {
    BaseCard,
    ContentBeforeBreak,
  },
  data() {
    return {
      canClick: false,
    } as Data
  },
  mounted() {
    type Id<T> = { [K in keyof T]: T[K] }
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
  watch: {
    openedKeys(to: Keys[]) {
      if (to.length <= 0) this.closeWindow()
    },
  },
  methods: {
    closeWindow() {
      this.removeFromOpenedKeys('menu')
      setTimeout(() => {
        const window = remote.getCurrentWindow()
        window.close()
      }, 350)
    },
    addToOpenedKeys(key: Keys) {
      const openedKeys = this.openedKeys
      if (!openedKeys.includes(key)) {
        openedKeys.push(key)
        // todo scrool down
      }
    },
    removeFromOpenedKeys(key: Keys) {
      const openedKeys = this.openedKeys
      if (openedKeys.includes(key)) {
        this.openedKeys = openedKeys.filter((openedKey) => openedKey !== key)
      }
    },
    async run(event: RunKey) {
      console.log(event)
      switch (event) {
        case 'start-long-break':
          return await setNextBreak.ask({
            forceNextBreakIn: 0,
            forceNextBreakType: 'long',
          })
        case 'open-stop-protection':
          return this.addToOpenedKeys('stop-protection')
        case 'open-settings':
          return this.addToOpenedKeys('settings')
      }
    },
  },
})
</script>
