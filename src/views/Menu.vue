<template>
  <div class="flex flex-col mx-16 flex-grow">
    <transition>
      <CardCloseable color="secondary-400" class="pointer-events-auto">
        <TheSettings />
      </CardCloseable>
    </transition>
  </div>
</template>

<script lang="ts">
import TheSettings from '../components/TheSettings.vue'
import CardCloseable from '../components/CardCloseable.vue'
import { remote } from 'electron'
import Vue from 'vue'

interface MousePolicy {
  _canClic: string
  (this: Window, event: PointerEvent): void
}

export default Vue.extend({
  components: {
    TheSettings,
    CardCloseable
  },
  data() {
    return {
      startDate: new Date(2020, 3, 1, 10, 10),
      endDate: new Date(2020, 3, 1, 10, 11)
    }
  },
  mounted() {
    const setIgnoreMouseEvents = remote.getCurrentWindow().setIgnoreMouseEvents

    addEventListener('pointerover', function mousePolicy(event) {
      mousePolicy._canClick =
        event.target === document.documentElement
          ? mousePolicy._canClick &&
            setIgnoreMouseEvents(true, { forward: true })
          : mousePolicy._canClick || setIgnoreMouseEvents(false) || 1
    } as MousePolicy)

    setIgnoreMouseEvents(true, { forward: true })
  }
})
</script>

<style lang="postcss">
body {
  @apply pointer-events-none;
}
</style>
