<script setup lang="ts">
import { computed, nextTick, onUnmounted, ref } from "vue";
import ButtonIcon from "./ButtonIcon.vue";
import CardCloseable from "./CardCloseable.vue";
import ContentSettings from "./ContentSettings.vue";
import { t, useI18n } from "@/i18n";

const emit = defineEmits<{ changeAutoFinishLock: [locked: boolean]; changed: [] }>();

const { t: tl } = useI18n({
  open: t("Show settings", "Ustawienia"),
  title: t("Settings", "Ustawienia"),
  fixing: t("Fixing settings", "Poprawiam ustawienia"),
  saveFailed: t("Could not save settings", "Nie udało się zapisać ustawień"),
});

const show = ref(false);
const hovering = ref(false);
const fixLog = ref<string[]>([]);
const failed = ref(false);
const form = ref<InstanceType<typeof ContentSettings>>();
const trigger = ref<InstanceType<typeof ButtonIcon>>();
const card = ref<InstanceType<typeof CardCloseable>>();
let timer: ReturnType<typeof setTimeout> | undefined;

const hasFixLog = computed(() => fixLog.value.length > 0 || failed.value);
const fixMessage = computed(() => (hasFixLog.value ? [failed.value ? tl("saveFailed") : tl("fixing"), ...fixLog.value].join(". ") : ""));

/**
 * Focus follows the card: into it on open, back to the trigger once the card is gone.
 * While the fix log shows, the card stays and so does focus (on its close button).
 */
async function restoreFocus() {
  await nextTick();
  if (show.value) return card.value?.focus();
  if (hasFixLog.value) return card.value?.focus();
  (trigger.value?.$el as HTMLElement | undefined)?.focus();
}
function setShow(to: boolean) {
  fixLog.value = [];
  failed.value = false;
  emit("changeAutoFinishLock", to);
  show.value = to;
  hovering.value = false;
  restoreFocus();
}

/** Closing saves first when something changed (explicit save, no save-on-unmount); Save changes closes too. */
async function close() {
  const result = form.value?.changed ? await form.value.save() : undefined;
  setShow(false);
  if (result && (result.messages.length || !result.ok)) {
    fixLog.value = result.messages;
    failed.value = !result.ok;
    clearLater(2000 + Math.max(1, result.messages.length) * 4000);
    restoreFocus();
  }
}

function clearLater(ms: number) {
  clearTimeout(timer);
  timer = setTimeout(() => {
    if (hovering.value) return clearLater(500);
    const hadFocus = card.value?.$el.contains(document.activeElement);
    fixLog.value = [];
    failed.value = false;
    if (hadFocus) restoreFocus();
  }, ms);
}
onUnmounted(() => clearTimeout(timer));
</script>

<template>
  <div class="relative flex w-full justify-end self-end">
    <!-- Always rendered: announces the fix log, which replaces the form inside the card. -->
    <p class="sr-only" role="status">{{ show ? "" : fixMessage }}</p>
    <ButtonIcon ref="trigger" class="is-large" :class="{ invisible: show || hasFixLog }" icon="settings" :content="tl('open')" @click="setShow(true)" />
    <Transition name="slide">
      <CardCloseable
        v-if="show || hasFixLog"
        ref="card"
        :title="tl('title')"
        absolute
        class="slide-leave-bottom right-0 bottom-0 z-40 max-h-[calc(100vh-2*var(--spacing-cover))] w-[360px]! max-w-[calc(100vw-2*var(--spacing-cover))]"
        @close="hasFixLog && !show ? setShow(false) : close()"
        @mouseenter="hovering = true"
        @mouseleave="hovering = false"
      >
        <div v-if="hasFixLog && !show">
          <p class="text-body" :class="failed ? 'text-destructive' : 'text-warning'">
            {{ failed ? tl("saveFailed") : tl("fixing") }}
          </p>
          <p v-for="line in fixLog" :key="line" class="mt-1 text-footnote text-label-secondary">{{ line }}</p>
        </div>
        <ContentSettings v-else ref="form" @changed="emit('changed')" @save="close" />
      </CardCloseable>
    </Transition>
  </div>
</template>
