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
        <TheSettings />
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
import TheSettings from '../components/TheSettings.vue'
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
}

export default Vue.extend({
  components: {
    TheSettings,
    CardCloseable,
    ContentMenu,
    ContentStopProtection,
  },
  data() {
    return {
      openedKeys: ['menu'],
    } as Data
  },
  mounted() {
    type Id<T> = { [K in keyof T]: T[K] }
    const setIgnoreMouseEvents = remote.getCurrentWindow().setIgnoreMouseEvents
    interface MousePolicyCanClick extends MousePolicy {
      this: Id<Window & { _canClick: boolean }>
      event: Event
    }
    if (isProd) {
      addEventListener('pointerover', function mousePolicy(event) {
        mousePolicy as MousePolicyCanClick
        mousePolicy._canClick =
          event.target === document.documentElement
            ? mousePolicy._canClick &&
              setIgnoreMouseEvents(true, { forward: true })
            : mousePolicy._canClick || setIgnoreMouseEvents(false) || 1
      } as MousePolicyCanClick)

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
      const window = remote.getCurrentWindow()
      window.close()
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
          return setNextBreak({
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
