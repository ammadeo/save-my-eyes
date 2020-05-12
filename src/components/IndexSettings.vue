<template>
  <div class="self-end w-full">
    <ButtonIcon
      icon="settings"
      content="Show settings"
      @click="showSettings = true"
    >
    </ButtonIcon>
    <BaseCard
      v-if="showSettings"
      color="secondary-300"
      class="absolute bottom-0 right-0"
      @focusout="showSettings = false"
    >
      <ContentSettings />
    </BaseCard>
  </div>
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'
import BaseCard from './BaseCard.vue'
import ContentSettings from './ContentSettings.vue'

import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

export default Vue.extend({
  components: {
    ButtonIcon,
    BaseCard,
    ContentSettings,
  },
  data() {
    return {
      showSettings: false,
    }
  },
})
</script>
