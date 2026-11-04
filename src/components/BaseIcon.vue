<script setup lang="ts">
import { computed } from "vue";
import { icons, type IconName } from "@/icons";

const props = defineProps<{ icon: IconName | "" }>();
const svg = computed(() => (props.icon ? (icons[props.icon] ?? "") : ""));
</script>

<template>
  <!-- eslint-disable-next-line vue/no-v-html -- trusted, bundled SVGs -->
  <span class="base-icon inline-flex shrink-0 items-center" aria-hidden="true" v-html="svg" />
</template>

<style scoped>
.base-icon :deep(svg) {
  height: 100%;
  width: auto;
  display: block;
}
</style>
