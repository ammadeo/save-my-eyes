<script setup lang="ts">
import { openUrl } from "@/bridge";
import { t, useI18n } from "@/i18n";

const props = defineProps<{ href: string }>();
const { t: tl } = useI18n({
  hint: t("The link will open in your default browser", "Link otworzy się w przeglądarce"),
});
const open = () => openUrl(props.href);
</script>

<template>
  <span class="link-hint" :data-hint="tl('hint')">
    <a :href="href" class="font-semibold underline" rel="noopener noreferrer" @click.prevent="open" @auxclick.prevent="open">
      <slot /> </a
    ><sup class="no-underline">↗</sup>
  </span>
</template>
