<template>
  <transition name="fade" mode="out-in">
    <img
      v-if="showIcon('close')"
      svg-inline
      src="@/assets/icons/close.svg"
      :alt="iconAlt"
      :class="classes"
    />
    <img
      v-else-if="showIcon('pause')"
      svg-inline
      src="@/assets/icons/pause.svg"
      :alt="iconAlt"
      :class="classes"
    />
    <img
      v-else-if="showIcon('settings')"
      svg-inline
      src="@/assets/icons/settings.svg"
      :alt="iconAlt"
      :class="classes"
    />
    <img
      v-else-if="showIcon('skip')"
      svg-inline
      src="@/assets/icons/skip.svg"
      :alt="iconAlt"
      :class="classes"
    />
    <img
      v-else-if="showIcon('start')"
      svg-inline
      src="@/assets/icons/start.svg"
      :alt="iconAlt"
      :class="classes"
    />
    <img
      v-else-if="showIcon('stop')"
      svg-inline
      src="@/assets/icons/stop.svg"
      :alt="iconAlt"
      :class="classes"
    />
    <img
      v-else-if="showIcon('mute')"
      svg-inline
      src="@/assets/icons/mute.svg"
      :alt="iconAlt"
      :class="classes"
    />
    <img
      v-else-if="showIcon('sound')"
      svg-inline
      src="@/assets/icons/sound.svg"
      :alt="iconAlt"
      :class="classes"
    />
    <img
      v-else-if="showIcon('finish')"
      svg-inline
      src="@/assets/icons/finish.svg"
      :alt="iconAlt"
      :class="classes"
    />
    <img
      v-else-if="showIcon('coffee')"
      svg-inline
      src="@/assets/icons/coffee.svg"
      :alt="iconAlt"
      :class="classes"
    />
  </transition>
</template>

<script lang="ts">
import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

export default Vue.extend({
  props: {
    icon: {
      type: String,
      required: true,
    },
    dark: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    showIcon(name: string): boolean {
      return this.icon === name
    },
  },
  computed: {
    iconAlt(): string {
      return `${this.icon} icon`
    },
    classes() {
      return [
        'fill-current',
        'w-auto',
        this.dark ? 'text-primary-800' : 'text-primary-100',
      ]
    },
  },
})
</script>
