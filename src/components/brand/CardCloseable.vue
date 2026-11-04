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
    <div class="mb-4 flex items-center justify-between gap-2">
      <p v-show="!content" class="text-headline text-label first-letter:uppercase">{{ title }}</p>
      <ButtonRoundable
        :class="content ? ['w-full', 'is-large'] : []"
        :content="content"
        :label="closeLabel"
        @click="emit('close')"
      />
    </div>
    <slot />
  </BaseCard>
</template>
