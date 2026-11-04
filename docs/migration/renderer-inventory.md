# Renderer port inventory (Vue 2 → Vue 3)

Produced 2026-11-04 from a read of `legacy-electron/src`. All `file:line` references are relative to `legacy-electron/`.

## Electron touch points in shared code

- `CheckIsLongBreak` (`utils/mixins/breaks.ts`) calls `rendererGetBreakData.ask({})` at `breaks.ts:11` and reads `getUserSettingsStore().get('breaks').long.every` at `breaks.ts:12`.
- `GetBreakTime` reads `getUserSettingsStore().get('breaks')` at `breaks.ts:30`.
- `TransparentClickEngine` calls `remote.getCurrentWindow().setIgnoreMouseEvents` at `transparentClickEngine.ts:15-26` (only when `isProd`) and again at `:31-32`.

## 1. Routes and views

Hash router (`src/router/index.ts`): `/` (alias `/index`) → Index, `/BeforeBreak`, `/menu`, `/blank`. Each Electron window loads one route.

**App.vue (shell)**
- Renders only `<router-view/>`.
- In `beforeMount` it loads the language: `navigator.language` is overridden by `store.get('lang')` (App.vue:15-20). Then it commits `i18n/setLang`.
- It commits `setSounds` from `store.get('sounds')` (App.vue:23-24).
- It re-subscribes recursively to `rendererEmitLanguage.listen()` (App.vue:28-37).

**index.vue (the break screen)**
- Full-screen dark grid (`grid-cols-base grid-rows-base`). Header title, a stop-protection pill at top right, an info line ("take a short break for 20 seconds"), a countdown clock with a progress bar, a Skip/Finish button, an idea card (or the donation card after a long break), and a settings button with a pop-over card.
- Composes: HeaderTitle, IndexStopProtection, TimerInfo, TimerClock, IndexTimerButton, IndexIdea, IndexSettings. Registers BaseCard, CardFocusable, ButtonRoundable, ButtonIcon but never uses them.
- Calls `setup()` in `mounted`, then plays the short or long mp3 with howler (index.vue:115-118, 141-147).
- On finish: if the break is short and not locked, it hides the window, plays the sound, then closes. Otherwise it calls `emitEndBreak` and plays the sound (index.vue:166-184).
- A lock system (`autoFinishLock`, `forceCloseLock`, `startCloseLock`) is driven by events from the children (index.vue:148-157).
- Electron: `checkIsLongBreak` (:125), `getBreakTime` (:127), `remote.getCurrentWindow().close()` (:159-160) and `.hide()` (:163-164), `rendererEmitEndBreak.ask({})` (:173).

**BeforeBreak.vue (pre-break toast)**
- Bottom-right card that slides in on a click-through transparent window. "short break will start in 5 seconds", a 5 s progress bar, Wait / Start / Skip buttons. If the user waits, an animejs scale pulse starts after 60 s (:69-81).
- Composes: BaseCard, ContentBeforeBreak.
- Electron: `TransparentClickEngine` (:37); `rendererStartBreak.ask({})` on the card's `after-leave`, then `$router.push('Index')` (:51-58), so the same window becomes the break window; `rendererSetNextBreak.ask({})` then `remote.getCurrentWindow().close()` (:62-64).
- `<style>` sets `body { @apply pointer-events-none }` (:86-90).

**Blank.vue (other-display overlay)**
- 50%-opacity title plus "Wait for break to end" (or "Break has ended"), and a bottom-right Skip/Finish button.
- Composes: HeaderTitle, BlankBreakButton. `<template funtional>` typo at :1 has no effect.
- Electron: `rendererEmitEndBreak.listen()` sets `finished` (:28-34); `rendererSetNextBreak.ask({})` on click (:44).

**Menu.vue (tray menu window)**
- Click-through window with one card at the bottom. `openedKey` switches between `menu` (ContentMenu), `settings` (ContentSettings `force-large`) and `stop-protection` (ContentStopProtection), each in CardCloseable, with a `slide` out-in transition.
- Closing sets `openedKey=''`. If settings changed it calls `setNextBreak({preventImmediateWindowClosing:true})`, then closes the window after 1000 ms (:76-90).
- Electron: `TransparentClickEngine` (:56); `remote` close (:80-81); `rendererSetNextBreak.ask` with `{preventImmediateWindowClosing}` (:86) and with `{forceNextBreakIn:0, forceNextBreakType:'long', forceSkipBeforeBreakView:true}` (:99-103).
- `<style>` also sets body `pointer-events-none`.

## 2. Components (27)

Shared traits: every component uses `Vue.extend`; none declares `emits`. Not used anywhere: filters, `$listeners`, `.sync`, `$scopedSlots`, functional components.

| Component | Props | Emits | Vue 2-only / notable | Libs / Electron |
|---|---|---|---|---|
| BaseButton | primary, center, absolute, disabled | click | `$emit('click')` on native `<button>` (:5); dynamic `group-hocus:`/`group-active:` classes | – |
| BaseCard | absolute | – | default slot; parents pass a dead `color` attr | – |
| BaseFocusTrap | active (req) | – | render fn returns `$slots.default[0]` (:7-13); `$el`; `beforeDestroy` (:51); watch immediate | focus-trap v5 |
| BaseIcon | icon (req), dark | – | 10× `<img svg-inline src="@/assets/icons/*.svg">` in `<transition out-in>` (:3-72); `fill-current`/`dark` no-ops (SVGs hard-code `fill:#c5cae9`) | vue-svg-inline-loader |
| BaseInputRange | value (req), max, min (req), scale=1, step=1, suffix, name (req), forceLarge | input (value*scale), blur | v-model value/input (:69, :160); `$useI18n`/`$t`; `$refs.input`; `col-gap-2` | – |
| BaseLink | href (req) | – | `$langLanguage` in template (:5); manual `auxclick`; `beforeDestroy` (:44) | `shell.openExternal` (:24, :41) |
| BaseProgressbar | min, max, value (req) | – | slot; inline translateX | – |
| BlankBreakButton | finished (req) | click (after 50 ms) | `$useI18n`; dead `centered` attr | – |
| ButtonIcon | disabled, content (req), icon (req), primary, absolute | click | re-emits click (double-fires in Vue 3 without `emits`); `first-letter:uppercase`; `flex-0` | – |
| ButtonRoundable | content, icon='close', primary, disabled | click | round when no content | – |
| ButtonToggle | on (req) | toggle(!on) | named slots iconOn/iconOff rendered twice | – |
| ButtonToggleLabeled | on, stateOn, stateOff (req) | toggle | forwards named slots | – |
| CardCloseable | absolute, title='save my eyes', content | close | `mixins()` no-arg; wraps BaseFocusTrap `active` | – |
| CardFocusable | absolute | focusin, focusout | `.native` (:6-7); `$refs.card.$el` (:40); `beforeDestroy` (:32). **Unused** | – |
| ContentBeforeBreak | – | break, skip, wait | mixins CreateTimer, CheckIsLongBreak, TimeAgoContent (:59); 60 s `setInterval`; Polish "minuta" hack (:123); `beforeDestroy` (:145) | animejs; IPC + store via mixin (:137) |
| ContentDonation | forceCloseLock (req) | – | `@click.once`; template `src="@/assets/images/appreciation.svg"` | `shell.openExternal` buymeacoffee (:63); `remote...close()` (:64) |
| ContentMenu | – | run(RunKey) | mixin CheckIsLongBreak; recursive 1 s `setTimeout` clock never cleared (:87-97) | `rendererGetBreakData.ask` (:102); date-fns |
| ContentSettings | forceLarge | changed, fixing(FixLog[]) | 4× v-model on BaseInputRange; `this.$watch` in beforeMount (:194); watches `$langLanguage`; **saves in `beforeDestroy`** (:232-241); `$store.commit` (:332, :341) | store get breaks/sounds/lang (:184-187), `.set(data)` (:239); `rendererEmitLanguage.ask({lang})` (:334) |
| ContentStopProtection | – | close | – | `rendererSetNextBreak.ask({forceNextBreakIn: 1-3 h, forceNextBreakType:'long'})` (:53); `rendererCloseApp.ask` (:64) |
| HeaderTitle | – | – | `$tGlobal('title')` | – |
| IndexIdea | long, finished, forceCloseLock (req) | – | random idea (6 ideas, inline `translate()`); `card.title[$langLanguage]` | 6 SVG images as URLs |
| IndexSettings | – | changeAutoFinishLock, changed | `.native` mouseenter/leave (:19-20); fix log 2 s + 4 s per entry, paused while hovered | – |
| IndexStopProtection | disabled | changeAutoFinishLock, close | `v-show` card with `slide-enter-right` | – |
| IndexTimerButton | long, finished, disabled | click (after 50 ms) | dead `centered` attr | – |
| ProgressbarIcon | min, max, value, icon (req), small | – | slot into BaseProgressbar; dead `color` attr | – |
| TimerClock | startDate, endDate (req), autoFinish | finished | mixin CreateTimer; `beforeDestroy` pauses anime (:78) | animejs; date-fns `format` 'mm : ss' |
| TimerInfo | startDate, endDate (req), long, finished | – | mixin TimeAgoContent; watches `$langLanguage`; 60 s interval; `beforeDestroy` (:56) | date-fns `formatDistanceStrict` |

`vue-typed-mixins` used by: BeforeBreak, Menu, index, CardCloseable, ContentBeforeBreak, ContentMenu, TimerClock, TimerInfo.

## 3. Global plugins and mixins

**i18n today** (`utils/mixins/i18n.ts`, `store/i18n.ts`, `types/vue.d.ts`)
- Namespaced Vuex module `i18n` with state `{ lang: 'en'|'pl', global: {title, breakLong, breakShort, timeAgoContentAgo, settingsSave, secondsSuffix} }`. Each entry is `{en, pl}` built with `translate(en, pl)`.
- `setLang` maps exactly `'pl'` to `pl`, everything else to `en` (i18n.ts:64-66), so `navigator.language` `'pl-PL'` becomes `en` (bug; the persisted store default masks it).
- Global mixin adds computed `$langGlobal`/`$langLanguage`, a non-reactive `$lang` filled by `this.$useI18n(t => ({key: t(en, pl)}))` in `beforeMount`, and `$t(id)` / `$tGlobal(id)` that throw in dev on missing keys. Reactivity comes only from `$langLanguage`.
- `utils/dateFnsI18n.ts` wraps `format`/`formatDistanceStrict` and picks `pl` or `enGB` from the store.
- Cross-window sync: `ContentSettings.setLang` commits locally and calls `emitLanguage.ask` (broadcast); `App.vue` listens and commits.

**i18n in Vue 3 (proposed)**
- No vue-i18n: 2 languages, ~100 strings, no plurals/interpolation.
- `src/i18n.ts` exports `lang = ref<'en'|'pl'>('en')`, `setLang(code)` using `code.startsWith('pl')`, `t(en, pl)`, the `global` dictionary, and `useI18n(dict)` returning `{ t, tg, lang }` with typed keys.
- Tauri `listen('lang-changed')` once in App `onMounted`, `unlisten` on unmount.
- Sounds state: a small reactive settings store. **Drop Vuex entirely.**

**`CreateTimer`** (`utils/mixins/createTimer.ts`): anime tweens `timePassedObj.timePassed` 0→`allTime` ms as a reactive clock. Proposal: `useCountdown(totalMs, onDone)` returning `{ elapsed, pause(), stop() }`, driven by `setInterval(250)` + `Date.now() - start` so it survives hidden/occluded webviews; stop in `onScopeDispose`. The BeforeBreak pulse becomes CSS `@keyframes` with `animation-delay: 60s`. This removes animejs.

**`TransparentClickEngine`**: production only; starts with `setIgnoreMouseEvents(true, {forward:true})`, a window `pointerover` listener toggles it. Tauri 2's `setIgnoreCursorEvents(bool)` has no `forward` option, so the webview receives nothing while ignoring and cannot detect re-entry. Needs a redesign (risk #1).

**Break mixins** → plain async functions in `breaks.ts`: `checkIsLongBreak()` (`breakIndex % settings.breaks.long.every === 0`), `getBreakTime(isLong)`, `timeAgoContent(endDate, withSuffix)`.

**Other utilities**: `utils/sound.ts` howler → `new Audio(url)` + `ended` promise, gated on `sounds.ui`. `utils/db.ts` `FixNumber`/`FixSettings` clamping + bilingual log text: port unchanged.

## 4. Styling

**`tailwind.config.js` (Tailwind 1.9) → Tailwind 4 `@theme`**

| Tailwind 1 | Tailwind 4 | 1:1? |
|---|---|---|
| `theme.colors` replaces the palette: black, white, transparent, `warn` (only `bg-warn-400` = `#f6ad55`), `secondary` 50-900 plus 1000/1050/1075/1100/1200, `primary` 50-900 | `@theme { --color-*: initial; --color-secondary-1050: …; … }` copy hex values | manual |
| fontFamily `display`: comfortaa, roboto; `body`: Source Sans Pro, roboto | `--font-display`, `--font-body` | yes |
| `gridTemplateColumns.base` = `minmax(20rem,1fr) minmax(2rem,4rem) minmax(min-content,20rem)` | `@utility grid-cols-base {…}` | no |
| `gridTemplateRows.base` = `auto auto 1fr auto` | `@utility grid-rows-base` | no |
| opacity 85, inset `full`, spacing 11/18/80/120, minHeight 8/12 | native | yes |
| translate `-card-40..64` | unused, drop | – |
| maxHeight `screen-16/24/32` = `calc(100vh - N)` | `max-h-[calc(100vh-4rem)]` | no |
| boxShadow `revers`, `lg-revers`, `xl-revers`, `inner-1`, `inner-2-top-2` | `--shadow-revers` etc. | yes |
| `tailwindcss-interaction-variants` (`hocus:`, `group-hocus:`, `group-active:`) | `@custom-variant hocus (&:hover, &:focus);` `@custom-variant group-hocus (:where(.group):is(:hover,:focus) &);` `group-active` native | no |
| custom `first-letter:` plugin | native | yes |
| purgecss whitelist (`utils/config/tailwind.js`) | drop; all dynamic classes are full literals | – |
| postcss-preset-env for nesting | `@tailwindcss/vite`; native nesting | – |

**Class renames (mechanical)**: `col-gap-2`→`gap-x-2`; `flex-grow`→`grow`, `flex-shrink-0`→`shrink-0`; `flex-0` (3×) delete (becomes `flex:0` in v4); `shadow`→`shadow-sm`, `rounded-sm`→`rounded-xs`, `outline-none`→`outline-hidden`; `transform` (6×) delete; `shadow-inner`→`inset-shadow-sm`, `shadow-xs`→`shadow-2xs`; `transition-transform delay-100` gains a 150 ms duration in v4 (BaseButton:13).

**Custom CSS (`src/assets/css`)**
- `main.css`: → `@import "tailwindcss"`.
- `initials.css`: body `pointer-events-none`; `::selection` + `.selection-darker::selection` (→ `selection:bg-primary-900`); number-spinner hiding; custom range track/thumb; `p, input, a { @apply font-body }` (→ `@layer base`, see risk #6).
- `gradients.css`: `.bg-gradient-card` radial gradient with `theme(colors.secondary.900 / 1050)` → `var(--color-…)`.
- `transitions.css`: `slide`/`fade` with Vue 2 names `.slide-enter`/`.fade-enter` (→ `-enter-from`); modifiers `slide-enter-right`, `slide-leave-bottom`, `slide-leave-left` used; `prefers-reduced-motion` branch.
- `transform3d.css`: `.perspective-64 { perspective: theme(sizes.64) }` → `16rem`.
- `scroll.css`: `.scroll-smooth` (native), `.scroll-sm` webkit scrollbar.
- `blend.css`: unused.
- `pseudoClasses.css`: `.after\:elevation*` unused; `.after\:link` + `@variants hocus { .after\:lang-en/pl::after }` is BaseLink's bilingual tooltip. `@variants` is gone and `after:` collides with v4's variant → rename to `.link-hint`, `content: attr(data-hint)` from i18n.
- `fonts.css`: `.font-preset-info`, `.font-preset-card-title` use `@screen md/lg/xl` → `@variant md` or `@utility`.
- SFC `<style lang="postcss">` with `@apply` (BeforeBreak:86, Menu:117) → plain CSS.

**Fonts** in `src/assets/fonts/`: `source-sans-pro-v13-latin-ext_latin-{300,regular,600}` (italic unused, drop) and `comfortaa-v28-latin-ext_latin-{300,regular,500}`. `@font-face` uses relative `url('../fonts/…')`, fine under Vite.

## 5. Assets

| Asset | Used by | Vite equivalent |
|---|---|---|
| `icons/*.svg` ×10 | BaseIcon | `import.meta.glob('./icons/*.svg', {query:'?raw', eager:true, import:'default'})` + `v-html`, or `vite-svg-loader`; replace hard-coded `fill:#c5cae9` with `currentColor` |
| `images/{window,plants,blink,mindfulness,outside,workout}.svg` | IndexIdea (URL import) | same import |
| `images/appreciation.svg` | ContentDonation template src | needs `@` alias in `vite.config.ts` |
| `images/book.svg` | nothing | drop |
| `music/short.mp3`, `long.mp3` | `utils/sound.ts` | URL import + `new Audio(url)` |
| `public/favicon.ico`, `icon.png`, `license.txt` | index.html/build | Vite `public/` |

## 6. Tests

20 spec files, 51 tests (~850 lines) on Jest + `@testing-library/vue` 5 + `@vue/test-utils` 1.0-beta. Mostly text/slot/aria/class assertions; behaviour tests for ContentBeforeBreak flow, ContentStopProtection IPC payloads, ContentMenu "Next short break in", TimerClock label/progress, BaseInputRange, BaseLink openExternal. They rely on `jest.mock('@/background/ipc' | '@/background/db' | 'electron')`.

**Recommendation**: drop the suite and port 5 specs to Vitest + `@testing-library/vue` v8: ContentBeforeBreak, ContentStopProtection, ContentMenu, TimerClock, BaseInputRange, mocking a single `@/bridge` module. The rest test Tailwind 1 class names and Vue 2 harness details the port changes anyway.

## 7. Risks (top 10)

1. **Click-through overlay** (`transparentClickEngine.ts:15-26`, BeforeBreak + Menu). No `{forward:true}` in Tauri. Mitigation: size the BeforeBreak and Menu windows to the card so no transparent overlay is needed; fallback a Rust-side cursor-position poll toggling ignore.
2. **Vue 3 transition class rename** (`transitions.css:9-17, 48`): `-enter` → `-enter-from`, incl. compound selectors.
3. **Undeclared emits + attrs fallthrough double-fire clicks, `.native` gone** (BaseButton:5, ButtonIcon:7, ButtonRoundable:8, IndexTimerButton:9, BlankBreakButton:8; `.native` at CardFocusable:6-7, IndexSettings:19-20). Mitigation: `defineEmits` everywhere, plain `@mouseenter` on root.
4. **Settings saved in `beforeDestroy`, racing IPC** (ContentSettings:232-241; Menu:76-78 sends `setNextBreak` before the unmount flush). Mitigation: explicit `save()` exposed by ContentSettings; parents await it before set-next-break/close.
5. **Synchronous electron-store reads in `beforeMount`** (App:17-24, ContentSettings:184-193, breaks.ts:12, 30). Mitigation: load settings once in `main.ts` before `app.mount` into a reactive store.
6. **Cascade layers in Tailwind 4** (`initials.css:54-56`): unlayered `p, input, a {font-body}` beats utilities. Put base CSS in `@layer base`.
7. **Clock is an animejs tween** (createTimer.ts:15-25, TimerClock:72-77): rAF throttled in hidden webviews. Use Date-based interval composable.
8. **One-shot `listen()` re-registered recursively; every `ask` leaks a listener** (App:28-37, Blank:28-34). Use Tauri `listen()` + `unlisten` in `onUnmounted`, `invoke` for request/response.
9. **Inline SVG loader + hard-coded fills** (BaseIcon:3-72). Glob `?raw` + `v-html` or vite-svg-loader; decide on `currentColor`.
10. **Tailwind 1-only CSS** (pseudoClasses.css:41-61, fonts.css:63-74, transform3d.css:2, BaseButton:51-59). `@custom-variant`, `@variant md`, rename `after:` classes, `var(--color-*)`.

Smaller: `remote.getCurrentWindow().close()/hide()` → `@tauri-apps/api/window` (index:159-164, BeforeBreak:63, Menu:80, ContentDonation:64); `shell.openExternal` → `@tauri-apps/plugin-opener` `openUrl` (BaseLink:41, ContentDonation:63); `process.env.NODE_ENV` → `import.meta.env.DEV`; `pl-PL`→`en` bug; ContentMenu timeout loop never cleared (:95).
