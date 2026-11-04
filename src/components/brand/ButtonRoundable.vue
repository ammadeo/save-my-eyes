<script setup lang="ts">
import { computed } from "vue";
import BaseButton from "./BaseButton.vue";
import BaseIcon from "../BaseIcon.vue";
import type { IconName } from "@/icons";

const props = withDefaults(
  defineProps<{ content?: string; icon?: IconName; primary?: boolean; disabled?: boolean; label?: string }>(),
  { content: "", icon: "close", primary: false, disabled: false, label: "" },
);
const emit = defineEmits<{ click: [] }>();
const round = computed(() => !props.content);
</script>

<template>
  <BaseButton
    :primary="primary"
    center
    :disabled="disabled"
    :class="round ? 'is-round' : ''"
    :aria-label="round ? label || undefined : undefined"
    @click="emit('click')"
  >
    <span v-if="!round" class="first-letter:uppercase">{{ content }}</span>
    <BaseIcon v-else :icon="icon" class="h-2.5 text-label-secondary" />
  </BaseButton>
</template>

<style scoped>
/* 28px quiet circle for icon-only buttons (close, pause). */
.glass-button.is-round {
  width: 28px;
  height: 28px;
  min-height: 28px;
  padding: 0;
  border-radius: 999px;
}
</style>
