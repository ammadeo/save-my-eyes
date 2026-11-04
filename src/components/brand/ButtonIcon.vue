<script setup lang="ts">
import BaseButton from "./BaseButton.vue";
import BaseIcon from "../BaseIcon.vue";
import type { IconName } from "@/icons";

withDefaults(
  defineProps<{ content: string; icon: IconName | ""; primary?: boolean; absolute?: boolean; disabled?: boolean }>(),
  { primary: false, absolute: false, disabled: false },
);
const emit = defineEmits<{ click: [] }>();
</script>

<template>
  <BaseButton :primary="primary" :absolute="absolute" :disabled="disabled" center @click="emit('click')">
    <span class="first-letter:uppercase">{{ content }}</span>
    <BaseIcon v-if="icon" :icon="icon" class="button-icon" />
  </BaseButton>
</template>

<style scoped>
.button-icon {
  height: 0.85em;
  opacity: 0.7;
}
</style>
