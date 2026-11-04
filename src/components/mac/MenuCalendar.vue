<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { getCalendarStatus, openCalendarPrivacy, setCalendarEnabled, type CalendarStatus } from "@/bridge";
import { t, useI18n } from "@/i18n";
import { useEvent } from "@/composables/useEvent";
import { log } from "@/log";
import { settings } from "@/settings";

const { t: tl } = useI18n({
  title: t("Meetings", "Spotkania"),
  toggle: t("Don't break during meetings", "Bez przerw w trakcie spotkań"),
  hint: t(
    "A break that falls during an event from the Calendar app starts a minute after it ends. For Google Calendar, add your Google account in System Settings › Internet Accounts.",
    "Przerwa wypadająca w trakcie wydarzenia z aplikacji Kalendarz zacznie się minutę po jego końcu. Aby użyć Kalendarza Google, dodaj konto Google w Ustawieniach systemowych › Konta internetowe.",
  ),
  denied: t("Save My Eyes has no access to your calendar.", "Save My Eyes nie ma dostępu do kalendarza."),
  openSettings: t("Open Privacy Settings…", "Otwórz ustawienia prywatności…"),
  notAsked: t("Calendar access is needed.", "Potrzebny jest dostęp do kalendarza."),
  allow: t("Allow…", "Zezwól…"),
});

/**
 * Applies at once instead of waiting for "Save changes": turning it on shows the macOS
 * permission prompt, which belongs right after the click.
 */
const status = ref<CalendarStatus>();
const busy = ref(false);

onMounted(async () => {
  try {
    status.value = await getCalendarStatus();
  } catch {
    // bridge already logged; the toggle falls back to settings
  }
});

useEvent("calendar-status", (next) => (status.value = next));

const enabled = computed(() => status.value?.enabled ?? settings.calendar.enabled);
const notAsked = computed(() => enabled.value && status.value?.access === "notDetermined");
const blocked = computed(
  () => enabled.value && (status.value?.access === "denied" || status.value?.access === "restricted"),
);

async function apply(on: boolean, input?: HTMLInputElement) {
  busy.value = true;
  try {
    status.value = await setCalendarEnabled(on);
  } catch (error) {
    log.error("calendar toggle failed", error);
    if (input) input.checked = enabled.value;
  } finally {
    busy.value = false;
  }
}

const toggle = (event: Event) => {
  const input = event.target as HTMLInputElement;
  return apply(input.checked, input);
};

async function openPrivacy() {
  await openCalendarPrivacy().catch(() => {});
}
</script>

<template>
  <div v-if="status?.access !== 'unsupported'">
    <h2 class="mac-section-title">{{ tl("title") }}</h2>
    <div class="mac-group">
      <label class="mac-row">
        <span class="grow">{{ tl("toggle") }}</span>
        <input
          :checked="enabled"
          :disabled="busy"
          v-bind="{ switch: '' }"
          type="checkbox"
          role="switch"
          class="mac-switch"
          @change="toggle"
        />
      </label>
      <div v-if="notAsked" class="mac-row warning" role="status">
        <span class="grow">{{ tl("notAsked") }}</span>
        <button type="button" class="mac-button" :disabled="busy" @click="apply(true)">{{ tl("allow") }}</button>
      </div>
      <div v-if="blocked" class="mac-row warning" role="status">
        <span class="grow">{{ tl("denied") }}</span>
        <button type="button" class="mac-button" @click="openPrivacy">{{ tl("openSettings") }}</button>
      </div>
    </div>
    <p class="mac-footnote">{{ tl("hint") }}</p>
  </div>
</template>

<style scoped>
.warning {
  background: var(--mac-warning-bg);
  color: var(--mac-warning-label);
  font-size: 12px;
}
</style>
