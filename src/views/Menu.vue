<template>
  <div
    class="flex flex-col max-w-full justify-end overflow-hidden px-16 flex-grow min-h-screen"
  >
    <transition name="slide" appear mode="out-in">
      <CardCloseable
        v-if="openedKey === 'stop-protection'"
        key="stop-protection"
        color="secondary-600"
        class="pointer-events-auto shadow-2xl mb-8"
        @close="closeWindow()"
      >
        <ContentStopProtection @close="closeWindow()" />
      </CardCloseable>

      <CardCloseable
        v-else-if="openedKey === 'settings'"
        key="settings"
        color="secondary-600"
        :content="cardSettingsContent"
        class="pointer-events-auto shadow-2xl mb-8"
        @close="closeWindow()"
      >
        <ContentSettings force-large @changed="settingsChanged = true" />
      </CardCloseable>
      <CardCloseable
        v-else-if="openedKey === 'menu'"
        key="menu"
        color="secondary-600"
        class="pointer-events-auto shadow-2xl mb-8"
        @close="closeWindow()"
      >
        <ContentMenu @run="run($event)" />
      </CardCloseable>
    </transition>
  </div>
</template>

<script lang="ts">
import ContentSettings from '../components/ContentSettings.vue'
import ContentMenu from '../components/ContentMenu.vue'
import ContentStopProtection from '../components/ContentStopProtection.vue'
import CardCloseable from '../components/CardCloseable.vue'
import { RunKey } from '@/types/menu'
import { remote } from 'electron'
import { rendererSetNextBreak as setNextBreak } from '@/background/ipc'
import { TransparentClickEngine } from '@/utils/mixins/transparentClickEngine'
import mixins from 'vue-typed-mixins'

type Key = 'menu' | 'settings' | 'stop-protection' | ''
interface Data {
  openedKey: Key
  settingsChanged: boolean
}

export default mixins(TransparentClickEngine).extend({
  components: {
    ContentSettings,
    CardCloseable,
    ContentMenu,
    ContentStopProtection,
  },
  data() {
    return {
      openedKey: 'menu',
      settingsChanged: false,
    } as Data
  },
  computed: {
    cardSettingsContent(): string {
      // todo merge with IndexSettings version when localizing
      return this.settingsChanged ? this.$tGlobal('settingsSave') : ''
    },
  },
  methods: {
    closeWindow() {
      this.openedKey = ''
      setTimeout(() => {
        const window = remote.getCurrentWindow()
        window.close()
      }, 1000)
    },
    open(key: Key) {
      this.openedKey = key
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
          return this.open('stop-protection')
        case 'open-settings':
          return this.open('settings')
      }
    },
  },
})
</script>

<style lang="postcss">
body {
  @apply pointer-events-none;
}
</style>
