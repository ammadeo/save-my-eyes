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
  <BaseButton :primary="primary" :absolute="absolute" :disabled="disabled" class="flex min-h-12" @click="emit('click')">
    <p class="px-4 py-2 font-display text-lg first-letter:uppercase">{{ content }}</p>
    <BaseIcon :icon="icon" class="h-4 pr-4 text-secondary-100" />
  </BaseButton>
</template>
