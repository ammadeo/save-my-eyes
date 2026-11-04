<script setup lang="ts">
import { computed } from "vue";
import ButtonIcon from "./ButtonIcon.vue";
import { t, useI18n } from "@/i18n";

const props = withDefaults(defineProps<{ long?: boolean; finished?: boolean; disabled?: boolean }>(), {
  long: false,
  finished: false,
  disabled: false,
});
const emit = defineEmits<{ click: [] }>();

const { t: tl } = useI18n({
  finishLong: t("Finish long break", "Zakończ długą przerwę"),
  finishShort: t("Finish short break", "Zakończ krótką przerwę"),
  skipLong: t("Skip long break", "Pomiń długą przerwę"),
  skipShort: t("Skip short break", "Pomiń krótką przerwę"),
});

const content = computed(() =>
  tl(`${props.finished ? "finish" : "skip"}${props.long ? "Long" : "Short"}` as "finishLong"),
);
</script>

<template>
  <ButtonIcon
    :primary="finished"
    :icon="finished ? 'finish' : 'skip'"
    :content="content"
    :disabled="disabled"
    class="is-xl self-start justify-self-end"
    @click="emit('click')"
  />
</template>
