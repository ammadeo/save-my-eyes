<script setup lang="ts">
import ButtonIcon from "./ButtonIcon.vue";
import { t, useI18n } from "@/i18n";

defineProps<{ finished: boolean }>();
const emit = defineEmits<{ click: [] }>();

const { t: tl } = useI18n({
  finish: t("Finish this break", "Zakończ przerwę"),
  skip: t("Skip this break", "Pomiń przerwę"),
});
</script>

<template>
  <ButtonIcon
    :icon="finished ? 'finish' : 'skip'"
    :content="finished ? tl('finish') : tl('skip')"
    :primary="finished"
    absolute
    class="right-0 bottom-0 m-8 origin-bottom-right scale-75 font-light tracking-wider lg:m-12 xl:m-16"
    @click="emit('click')"
  />
</template>
