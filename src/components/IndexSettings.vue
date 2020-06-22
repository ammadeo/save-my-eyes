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
        v-if="showSettings"
        color="secondary-300"
        :content="closeContent"
        :title="$t('title')"
        absolute
        class="bottom-0 right-0 z-40 slide-leave-bottom max-h-screen-16 lg:max-h-screen-24 xl:max-h-screen-32"
        @close="setShowSettings(false)"
      >
        <ContentSettings @changed="changed = true" />
      </CardCloseable>
    </transition>
  </div>
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'
import CardCloseable from './CardCloseable.vue'
import ContentSettings from './ContentSettings.vue'

import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

export default Vue.extend({
  components: {
    ButtonIcon,
    CardCloseable,
    ContentSettings,
  },
  data() {
    return {
      showSettings: false,
      changed: false,
    }
  },
  beforeMount() {
    this.$useI18n((t) => ({
      open: t('Show settings', 'Ustawienia'),
      title: t('Settings', 'Ustawienia'),
    }))
  },
  methods: {
    setShowSettings(to: boolean) {
      this.$emit('changeAutoFinishLock', to)
      this.showSettings = to
      if (to === false) this.changed = false
    },
  },
  computed: {
    closeContent(): string {
      return this.changed ? this.$tGlobal('settingsSave') : ''
    },
  },
})
</script>
