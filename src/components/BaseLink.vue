<template>
  <span
    class="after:link"
    :class="
      this.$langLanguage === 'pl'
        ? ['hocus:after:lang-pl']
        : ['hocus:after:lang-en']
    "
    ><a
      @click.prevent="openLink($event)"
      :href="href"
      hreflang="en"
      target="_blank"
      class="underline font-semibold"
      rel="noopener noreferrer"
      ref="link"
      ><slot /></a
    ><sup class="no-underline">↗️</sup>
  </span>
</template>

<script lang="ts">
import Vue from 'vue'
import { shell } from 'electron'

export default Vue.extend({
  props: {
    href: {
      type: String,
      required: true,
    },
  },
  mounted() {
    const link = this.$refs.link as HTMLLinkElement
    link.addEventListener('auxclick', this.openLink)
  },
  methods: {
    async openLink(event: MouseEvent) {
      event.preventDefault()
      const link = (event.target as HTMLLinkElement).href
      await shell.openExternal(link)
    },
  },
  beforeDestroy() {
    const link = this.$refs.link as HTMLLinkElement
    link.removeEventListener('auxclick', this.openLink)
  },
})
</script>
