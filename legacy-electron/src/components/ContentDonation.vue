<template>
  <div class="flex m-4">
    <img
      class="mr-4 w-48 md:w-56 lg:w-64"
      src="@/assets/images/appreciation.svg"
      :alt="$t('imageAlt')"
      data-testid="idea-img"
    />
    <div class="flex flex-col">
      <h3
        class="font-preset-card-title mb-2 text-secondary-50"
        data-testid="idea-title"
      >
        {{ $t('title') }}
      </h3>
      <p class="mb-4 text-lg text-secondary-100" data-testid="idea-content">
        {{ $t('description') }}
      </p>
      <ButtonIcon
        @click.once="openCoffee"
        primary
        :disabled="forceCloseLock"
        icon="coffee"
        :content="$t('link')"
      />
      <p class="text-sm self-center text-secondary-200">
        {{ $t('note') }}
      </p>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import ButtonIcon from './ButtonIcon.vue'
// import mixins from 'vue-typed-mixins'
import { shell, remote } from 'electron'
export default Vue.extend({
  components: { ButtonIcon },
  props: {
    forceCloseLock: {
      type: Boolean,
      required: true,
    },
  },
  beforeMount() {
    this.$useI18n((t) => ({
      imageAlt: t('Spread love', 'Podziel się miłością'),
      title: t('Like what You see?', 'Podoba Ci się aplikacja?'),
      description: t(
        `Consider supporting development of this project`,
        'Rozważ wsparcie rozwoju tego projektu'
      ),
      link: t('Buy me a coffee', 'Zamów mi kawę'),
      note: t(
        'Will open Your default browser',
        'Otworzy się w Twojej przeglądarce'
      ),
    }))
  },
  methods: {
    async openCoffee() {
      await shell.openExternal('https://buymeacoffee.com/ammadeo')
      remote.getCurrentWindow().close()
    },
  },
})
</script>
