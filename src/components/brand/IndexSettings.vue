<script setup lang="ts">
import { computed, onUnmounted, ref } from "vue";
import ButtonIcon from "./ButtonIcon.vue";
import CardCloseable from "./CardCloseable.vue";
import ContentSettings from "./ContentSettings.vue";
import { t, useI18n } from "@/i18n";

const emit = defineEmits<{ changeAutoFinishLock: [locked: boolean]; changed: [] }>();

const { t: tl, tg } = useI18n({
  open: t("Show settings", "Ustawienia"),
  title: t("Settings", "Ustawienia"),
  fixing: t("Fixing settings", "Poprawiam ustawienia"),
  saveFailed: t("Could not save settings", "Nie udało się zapisać ustawień"),
});

const show = ref(false);
const changed = ref(false);
const hovering = ref(false);
const fixLog = ref<string[]>([]);
const failed = ref(false);
const form = ref<InstanceType<typeof ContentSettings>>();
let timer: ReturnType<typeof setTimeout> | undefined;

const hasFixLog = computed(() => fixLog.value.length > 0 || failed.value);

function setShow(to: boolean) {
  fixLog.value = [];
  failed.value = false;
  emit("changeAutoFinishLock", to);
  show.value = to;
  if (!to) changed.value = false;
  hovering.value = false;
}

/** The close button saves first when something changed (explicit save, no save-on-unmount). */
async function close() {
  const result = changed.value && form.value ? await form.value.save() : undefined;
  setShow(false);
  if (result && (result.messages.length || !result.ok)) {
    fixLog.value = result.messages;
    failed.value = !result.ok;
    clearLater(2000 + Math.max(1, result.messages.length) * 4000);
  }
}

function clearLater(ms: number) {
  clearTimeout(timer);
  timer = setTimeout(() => {
    if (hovering.value) return clearLater(500);
    fixLog.value = [];
    failed.value = false;
  }, ms);
}
onUnmounted(() => clearTimeout(timer));

function onChanged() {
  changed.value = true;
  emit("changed");
}
</script>

<template>
  <div class="relative w-full self-end">
    <ButtonIcon class="is-large w-full" :class="{ invisible: show || hasFixLog }" icon="settings" :content="tl('open')" @click="setShow(true)" />
    <Transition name="slide">
      <CardCloseable
        v-if="show || hasFixLog"
        :content="changed ? tg('settingsSave') : ''"
        :title="tl('title')"
        absolute
        class="slide-leave-bottom right-0 bottom-0 z-40 max-h-[calc(100vh-2*var(--spacing-cover))]"
        @close="hasFixLog && !show ? setShow(false) : close()"
        @mouseenter="hovering = true"
        @mouseleave="hovering = false"
      >
        <div v-if="hasFixLog && !show" aria-live="polite">
          <p class="text-body" :class="failed ? 'text-destructive' : 'text-warning'">
            {{ failed ? tl("saveFailed") : tl("fixing") }}
          </p>
          <p v-for="line in fixLog" :key="line" class="mt-1 text-footnote text-label-secondary">{{ line }}</p>
        </div>
        <ContentSettings v-else ref="form" @changed="onChanged" />
      </CardCloseable>
    </Transition>
  </div>
</template>
