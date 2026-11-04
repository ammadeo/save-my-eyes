<script setup lang="ts">
import BaseProgressbar from "./BaseProgressbar.vue";
import BaseIcon from "../BaseIcon.vue";
import type { IconName } from "@/icons";

withDefaults(defineProps<{ min: number; max: number; value: number; icon: IconName | ""; small?: boolean }>(), {
  small: false,
});
</script>

<template>
  <BaseProgressbar :min="min" :max="max" :value="value">
    <BaseIcon
      class="absolute top-0 right-0 mx-4 h-4 text-secondary-100"
      :class="small ? ['my-2'] : ['my-4']"
      :icon="icon"
    />
  </BaseProgressbar>
</template>
