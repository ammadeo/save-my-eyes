<script setup lang="ts">
import BaseProgressbar from "./BaseProgressbar.vue";
import BaseIcon from "../BaseIcon.vue";
import type { IconName } from "@/icons";

withDefaults(defineProps<{ min: number; max: number; value: number; icon: IconName | ""; small?: boolean }>(), {
  small: false,
});
</script>

<template>
  <div class="flex w-full items-center gap-3">
    <BaseProgressbar class="flex-1" :min="min" :max="max" :value="value" />
    <!-- Hint at the bar's end: the break closes itself when the time is up. -->
    <BaseIcon v-if="icon" :icon="icon" class="text-label-tertiary" :class="small ? 'h-2.5' : 'h-3'" />
  </div>
</template>
