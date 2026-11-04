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
    :center="round"
    :disabled="disabled"
    class="align-baseline"
    :class="round ? ['h-8', 'w-8'] : ['min-h-8']"
    :aria-label="round ? label || undefined : undefined"
    @click="emit('click')"
  >
    <p v-show="!round" class="my-1 mr-2 ml-4 font-display text-lg">{{ content }}</p>
    <BaseIcon :icon="icon" class="m-1 h-3 text-secondary-100" :class="round ? [] : ['pr-4']" />
  </BaseButton>
</template>
