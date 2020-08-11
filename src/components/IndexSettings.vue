<template>
  <div class="self-end w-full relative">
    <ButtonIcon
      class="w-full"
      icon="settings"
      :content="$t('open')"
      @click="setShowSettings(true)"
    >
    </ButtonIcon>
    <transition name="slide">
      <CardCloseable
        v-if="showSettings || hasFixLog"
        color="secondary-300"
        :content="closeContent"
        :title="$t('title')"
        absolute
        class="bottom-0 right-0 z-40 slide-leave-bottom max-h-screen-16 lg:max-h-screen-24 xl:max-h-screen-32"
        @close="setShowSettings(false)"
        @mouseenter.native="hovering = true"
        @mouseleave.native="hovering = false"
      >
        <div v-if="hasFixLog">
          <p class="text-secondary-100 text-lg">
            {{ $t('fixing') }}
          </p>
          <p v-for="log in fixLog" :key="log.code" class="text-secondary-100">
            {{ log.message }}
          </p>
        </div>

        <ContentSettings
          v-else
          @changed="setChanged"
          @fixing="fixingSettingWarning($event)"
        />
      </CardCloseable>
    </transition>
  </div>
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'
import CardCloseable from './CardCloseable.vue'
import ContentSettings from './ContentSettings.vue'
import { FixLogSettings } from '@/utils/db'
import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

interface Data {
  showSettings: boolean
  changed: boolean
  hovering: boolean
  fixLog: FixLogSettings[]
}

export default Vue.extend({
  components: {
    ButtonIcon,
    CardCloseable,
    ContentSettings,
  },
  data(): Data {
    return {
      showSettings: false,
      changed: false,
      fixLog: [],
      hovering: false,
    }
  },
  beforeMount() {
    this.$useI18n((t) => ({
      open: t('Show settings', 'Ustawienia'),
      title: t('Settings', 'Ustawienia'),
      fixing: t('Fixing settings', 'Poprawiam ustawienia'),
    }))
  },
  methods: {
    setShowSettings(to: boolean): void {
      this.fixLog = []
      this.$emit('changeAutoFinishLock', to)
      this.showSettings = to
      if (to === false) this.changed = false
      this.hovering = false
    },
    setChanged(): void {
      this.changed = true
      this.$emit('changed')
    },
    fixingSettingWarning(fixLog: FixLogSettings[]): void {
      this.fixLog = fixLog
      this.timeoutClearFixLog(2000 + fixLog.length * 4000)
    },
    timeoutClearFixLog(timeout: number) {
      setTimeout(() => {
        if (this.hovering) return this.timeoutClearFixLog(500)
        this.fixLog = []
      }, timeout)
    },
  },
  computed: {
    closeContent(): string {
      return this.changed ? this.$tGlobal('settingsSave') : ''
    },
    hasFixLog(): boolean {
      return this.fixLog.length > 0
    },
  },
})
</script>
