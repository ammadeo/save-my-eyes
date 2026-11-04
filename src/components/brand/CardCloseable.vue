<script setup lang="ts">
import BaseCard from "./BaseCard.vue";
import ButtonRoundable from "./ButtonRoundable.vue";

withDefaults(defineProps<{ absolute?: boolean; title?: string; content?: string; closeLabel?: string }>(), {
  absolute: false,
  title: "save my eyes",
  content: "",
  closeLabel: "Close",
});
const emit = defineEmits<{ close: [] }>();
</script>

<template>
  <BaseCard :absolute="absolute">
    <div class="flex flex-col p-4">
      <div class="flex justify-between">
        <p v-show="!content" class="text-xl text-secondary-100 uppercase">{{ title }}</p>
        <ButtonRoundable
          primary
          :class="content ? ['w-full'] : []"
          :content="content"
          :label="closeLabel"
          @click="emit('close')"
        />
      </div>
      <slot />
    </div>
  </BaseCard>
</template>
