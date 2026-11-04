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
  <a
    :href="href"
    :title="tl('hint')"
    class="font-medium"
    rel="noopener noreferrer"
    @click.prevent="open"
    @auxclick.prevent="open"
    ><slot
  /></a>
</template>
