<template>
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
        this.dark ? 'text-primary-800' : 'text-primary-100',
      ]
    },
  },
})
</script>
