<template>
  <div
    class="flex flex-col justify-end overflow-hidden px-16 flex-grow min-h-screen"
  >
    <transition-group name="slide" appear>
      <CardCloseable
        v-if="openedKeys.includes('menu')"
        key="menu"
        color="secondary-600"
        class="pointer-events-auto shadow-2xl mb-8"
        @close="closeWindow()"
      >
        <ContentMenu @run="run($event)" />
      </CardCloseable>
      <CardCloseable
        v-if="openedKeys.includes('settings')"
        key="settings"
        color="secondary-600"
        class="pointer-events-auto mb-8"
        @close="removeFromOpenedKeys('settings')"
      >
        <ContentSettings />
      </CardCloseable>
      <CardCloseable
        v-if="openedKeys.includes('stop-protection')"
        key="stop-protection"
        color="secondary-600"
        class="pointer-events-auto mb-8"
        @close="removeFromOpenedKeys('stop-protection')"
      >
        <ContentStopProtection @close="closeWindow()" />
      </CardCloseable>
    </transition-group>
  </div>
</template>

<script lang="ts">
import ContentSettings from '../components/ContentSettings.vue'
import ContentMenu from '../components/ContentMenu.vue'
import ContentStopProtection from '../components/ContentStopProtection.vue'
import CardCloseable from '../components/CardCloseable.vue'
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
    ContentSettings,
    CardCloseable,
    ContentMenu,
    ContentStopProtection,
  },
  data() {
    return {
      openedKeys: ['menu'],
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
    run(event: RunKey) {
      console.log(event)
      switch (event) {
        case 'start-long-break':
          return setNextBreak.ask({
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

<style lang="postcss">
.slide-enter-active,
.slide-leave-active {
  transition: transform 300ms;
}

.slide-enter {
  transform: translateY(100vw);
}
.slide-leave-to {
  transform: translateX(100%);
}
.slide-move {
  transition: transform 300ms;
}
body {
  @apply pointer-events-none;
}
</style>
