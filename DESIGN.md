---
name: Save My Eyes
description: Sage-tinted Liquid Glass windows that follow macOS, with only what has to be there.
colors:
  accent: "oklch(52% 0.07 150)"
  accent-dark: "oklch(76% 0.08 150)"
  accent-pressed: "oklch(46% 0.07 150)"
  accent-pressed-dark: "oklch(70% 0.08 150)"
  on-accent: "oklch(99% 0.005 150)"
  on-accent-dark: "oklch(20% 0.03 150)"
  label: "oklch(22% 0.02 150 / 0.9)"
  label-dark: "oklch(97% 0.01 150 / 0.9)"
  label-secondary: "oklch(22% 0.02 150 / 0.65)"
  label-secondary-dark: "oklch(97% 0.01 150 / 0.65)"
  label-tertiary: "oklch(22% 0.02 150 / 0.3)"
  label-tertiary-dark: "oklch(97% 0.01 150 / 0.3)"
  surface: "oklch(100% 0 0 / 0.45)"
  surface-dark: "oklch(100% 0 0 / 0.07)"
  fill: "oklch(22% 0.02 150 / 0.06)"
  fill-dark: "oklch(97% 0.01 150 / 0.09)"
  fill-pressed: "oklch(22% 0.02 150 / 0.1)"
  fill-pressed-dark: "oklch(97% 0.01 150 / 0.16)"
  control-neutral: "oklch(55% 0.01 150)"
  control-neutral-dark: "oklch(80% 0.01 150)"
  separator: "oklch(22% 0.02 150 / 0.1)"
  separator-dark: "oklch(97% 0.01 150 / 0.1)"
  warning: "oklch(50% 0.11 75)"
  destructive: "oklch(50% 0.16 25)"
  destructive-dark: "oklch(76% 0.13 25)"
  glass-tint: "oklch(70% 0.06 150 / 0.14)"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "clamp(56px, 9vw, 96px)"
    fontWeight: 300
    lineHeight: 1
    letterSpacing: "-0.02em"
  large-title:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "26px"
    fontWeight: 400
    lineHeight: "32px"
  title-2:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 500
    lineHeight: "22px"
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: "16px"
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "16px"
  footnote:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: "14px"
  control-xl:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 500
    lineHeight: "20px"
rounded:
  control: "8px"
  control-xl: "12px"
  group: "14px"
  panel: "18px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  cover: "clamp(32px, 5vw, 64px)"
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.on-accent}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "4px 14px"
  button-primary-active:
    backgroundColor: "{colors.accent-pressed}"
  button-quiet:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.label}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "4px 14px"
  button-quiet-active:
    backgroundColor: "{colors.fill-pressed}"
  group:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.group}"
    padding: "0"
  row:
    textColor: "{colors.label}"
    typography: "{typography.body}"
    padding: "8px 12px"
---

# Design System: Save My Eyes

Reference captures of the shipped windows on real Liquid Glass (dark appearance) live in `docs/design/`.

## Overview

**Creative North Star: "A pane of sage glass over your desk"**

The app has no surface of its own. Every window is a sheet of Liquid Glass that the system renders behind the SwiftUI content (the views paint no background), so a break is not a navy screen slammed over your work, it is your work receding behind frosted glass, tinted faintly green. Light and dark are never chosen by the app: the glass takes its luminance from whatever is behind it and from the user's macOS appearance, and the labels follow with semantic alpha colours.

Everything on the glass is monochrome except two things: the one action that matters right now (start a long break, finish the break) and the progress of time. Those are sage. Nothing else is coloured. Text is the system font at Apple's macOS sizes; there is no display face, no uppercase tracking, no brand lockup. The break cover keeps the old layout's bones (title, countdown, idea card, exit button, settings) but each is reduced to its minimum, with generous air between them.

The old look (deep navy, Comfortaa and Source Sans Pro, pill buttons with stacked shadows, tinted icon chips) is rejected in full. Nothing from it survives as a style; only the content, the behaviour and the illustrations.

**Key Characteristics:**
- Native glass material, never a painted background
- One accent, sage, used on at most one control and one progress fill per screen
- System font only, Apple's macOS text styles
- Monochrome icons and labels with alpha, not grey
- Translucent white groups on the glass, hairline separators, no shadows inside the window

## Colors

Sage on glass: a single muted green against translucent white and alpha-black labels.

### Primary
- **Sage** (`oklch(52% 0.07 150)` light, `oklch(76% 0.08 150)` dark): background of the single prominent button on a screen, the progress fill and the on-state of a switch (a state indicator, not a control). Never used for text. Light sage is dark enough for 13px white text at 4.5:1.
- **Sage pressed** (`oklch(46% 0.07 150)` / `oklch(70% 0.08 150)`): the prominent button while pressed.
- **Glass tint** (`oklch(70% 0.06 150 / 0.14)`): passed to the native material as its tint colour so the whole window reads faintly sage.

### Neutral
- **Label** (`oklch(22% 0.02 150 / 0.9)` light, `oklch(97% 0.01 150 / 0.9)` dark): all primary text and icons.
- **Label secondary** (alpha 0.65): captions, section titles, footnotes, status lines. This is the lowest alpha allowed for readable text: 0.65 keeps 11px footnotes at 4.5:1 on light glass (0.55 measured ~3.6:1).
- **Label tertiary** (alpha 0.3): chevrons, shortcuts, disabled text. Decoration only, never the sole carrier of information.
- **Surface** (`oklch(100% 0 0 / 0.45)` light, `oklch(100% 0 0 / 0.07)` dark): grouped lists, cards, quiet buttons.
- **Fill** (`oklch(22% 0.02 150 / 0.06)` / `oklch(97% 0.01 150 / 0.09)`): progress tracks, notices. **Fill pressed** (alpha 0.1 / 0.16): rows and quiet buttons while pressed.
- **Control neutral** (`oklch(55% 0.01 150)` / `oklch(80% 0.01 150)`): the tint of native sliders, so a form of four sliders stays monochrome.
- **Separator** (alpha 0.1 of the label hue): hairlines between rows.

### Tertiary
- **Warning** (`oklch(50% 0.11 75)` light, `oklch(78% 0.12 80)` dark): the "fixing settings" notice only.
- **Destructive** (`oklch(50% 0.16 25)` / `oklch(76% 0.13 25)`): text of "Turn off for this session" and "Quit".

### Increase Contrast
When macOS Increase contrast is on (`prefers-contrast: more`), labels go opaque or 0.82 alpha, tertiary 0.6, separators 0.35, surfaces firmer, and sage darkens (light) or lightens (dark) one step. Same hues, no new colours.

### Named Rules
**The One Sage Rule.** At most one sage-filled control per screen, plus the progress fill and the on-state of switches. Sliders are neutral. If a second control wants colour, it becomes quiet. A floating card on the cover (settings, stop protection) counts as its own screen while open: its Save may be sage.
**The No-Paint Rule.** No element paints an opaque background. Surfaces are alpha white or alpha label; the glass must show through everywhere.

## Typography

**Display Font:** system (`-apple-system, BlinkMacSystemFont, system-ui, sans-serif`)
**Body Font:** system (same stack)

**Character:** San Francisco at Apple's own macOS sizes, so the windows read as part of the system. The only typographic gesture is the countdown, set light and large on the cover.

### Hierarchy
- **Display** (300, `clamp(56px, 9vw, 96px)`, 1, tabular numerals, -0.02em): the countdown on the break cover.
- **Large Title** (400, 26/32): the break info line ("take a short break for 20 seconds").
- **Title 2** (500, 17/22): the idea card title, the menu countdown value is 26/32 at 500.
- **Headline** (600, 13/16): window titles, the before-break card title.
- **Body** (400, 13/16): every row and field. Push-button labels are the same size at weight 500.
- **Footnote** (400, 11/14): section titles (secondary label), credits, hints.
- **Control XL** (500, 15/20): the label of the cover's 40px exit button only.

### Named Rules
**The Weight Rule.** Regular, Medium and Semibold only; Light is allowed for the countdown alone.
**The Case Rule.** No uppercase, no letter-spacing on text; `::first-letter` capitalisation handles sentence starts.

## Layout

Four windows. The menu window is 400px wide and is sized to its pane (52px toolbar + pane + 16px), re-measured when the pane grows, so no pane floats in empty glass; it is a single column with 16px side gutters and 14px between groups. The before-break card is 360px wide and sized to its content: icon + text column, actions 12px below the text, 14px padding. The break cover keeps a three-column grid (content, gutter, actions) with `clamp(32px, 5vw, 64px)` page padding: title row, info, countdown, idea card bottom-left, exit button top-right of the actions column, settings bottom-right. Blank covers centre a single caption with the exit button bottom-right. Rows are at least 40px tall; hit targets are never under 24px.

## Elevation & Depth

Depth comes from the material, not from shadows. The native window shadow is the only shadow. Inside a window, hierarchy is three levels of translucency: glass (window), surface (groups and cards), fill (pressed and tracks). Overlapping cards on the break cover (settings, stop protection) use a slightly stronger surface (`oklch(100% 0 0 / 0.6)` light, `/ 0.12` dark) and a 0.5px alpha border so they separate from the group beneath.

### Named Rules
**The No-Shadow Rule.** No `box-shadow` inside a window except the 0.5px hairline on quiet buttons.

## Shapes

Continuous, concentric rounding. Controls 8px, groups and cards 14px, the before-break panel 18px, sliders and switches native. Inner radius = outer radius minus padding where things nest (a 14px card with 12px padding holds 2px-radius children, i.e. effectively square content). Borders are 0.5px alpha hairlines or absent.

## Components

### Buttons
- **Shape:** 8px radius, 24px min height (28px large), 4px 14px padding. The cover's exit button is the one XL control: 40px tall, 12px radius, 15px label.
- **Primary:** sage background, on-accent text, no border. Pressed: sage pressed.
- **Quiet:** surface background, label text, 0.5px separator border. Pressed: fill pressed.
- **Destructive:** quiet with destructive text.
- **Disabled:** opacity 0.45.
- **Hover / Focus:** no hover colour on buttons (macOS convention); focus-visible ring is 3px opaque sage (a translucent ring fell under 3:1 on light glass), 1px outside the element and following its own radius. Inside a group the ring sits 3px inside the row.

### Cards / Containers
- **Corner Style:** 14px.
- **Background:** surface; stronger surface for floating cards on the cover.
- **Shadow Strategy:** none.
- **Border:** 0.5px separator.
- **Internal Padding:** 12–14px.

### Inputs / Fields
- **Sliders:** native `Slider` tinted control-neutral. **Switches:** native, sage when on.
- **Select:** native popup.
- **Focus:** the shared focus ring.

### Rows (grouped list)
- 40px min height, 8px gap, 12px side padding, hairline separator between rows inset to the text start (12px, 40px after an icon), fill pressed on press, no hover colour on glass.
- Leading icon: monochrome label-secondary SVG, 11–13px, no tinted chip. Trailing chevron is a drawn 7×12 stroke in label-tertiary.
- The Quit row is the only destructive row (destructive label). "Buy me a coffee" is a footnote link in the settings credits, not a row.

### Progress
- 4px (card) or 8px (cover) track in fill, sage bar, pill radius.

### Countdown (signature)
The break cover's clock: display-size light numerals, tabular, a wide sage progress bar beneath, fading to 0.25 opacity once the time is up.

## Imagery

The seven unDraw illustrations (`SaveMyEyes/Resources/Images/*.svg`) are recoloured into the system and are the only polychrome objects on the cover. They are plain SVG files loaded as `NSImage`, so their colours are literal:

- **sage-700** `#4F6E5A` main garments and far trees; **sage-500** `#6B8F77` the main object (balls, leaves, mug, sky); **sage-300** `#A9C4B0` light garments and backdrops.
- **clay-500** `#B8A58B` and **clay-300** `#D9CBB8` the quiet second hue (tops, birds, sprouts) where unDraw used pink or yellow.
- **ink** `#2E3A33` and **ink-2** `#45554B` outlines, hair, furniture, instead of unDraw's navy.
- Skin tones and plain greys are unDraw's own; brick texture in `window.svg` is `#8fa394` so it reads softly on both appearances.
- No blue, purple, pink or yellow may return. Keep each picture at 128–160px tall inside its card.

The app icon is the same world: a sage-500 tile, a pale sage eyeball and a sage-700 plus for its pupil, three flat layers and nothing else. `SaveMyEyes/Resources/Images/app-icon.svg` is the flattened master on the macOS icon grid; `SaveMyEyes/Resources/Icons/AppIcon.icon` holds the same shapes as Icon Composer layers, so macOS 26+ renders it as Liquid Glass (specular, shadow, dark and clear variants come from the system). The menu-bar tray icon stays a monochrome template.

## Do's and Don'ts

### Do:
- **Do** let the native material paint the window (`Sources/Windows/GlassBacking.swift`); views paint no background.
- **Do** use alpha label colours for text and icons so they stay legible in both appearances and under Reduce Transparency.
- **Do** keep every window to one sage control; sliders stay neutral.
- **Do** size a window to its SwiftUI content (fixed width, intrinsic height) instead of hard-coding a height.
- **Do** use the system font at 13px body, 11px footnote, Apple's macOS scale above.
- **Do** move focus with what opens: into a floating card (its close button) or a menu pane (its title), and back to the control that opened it on close. Floating cards are `role="dialog"` and close on Escape.
- **Do** keep live regions (`role="status"`) mounted and change only their text; never put a ticking countdown inside one.

### Don't:
- **Don't** add tinted icon chips, gradients, pills, stacked shadows or uppercase labels; those belong to the rejected look.
- **Don't** paint a solid background anywhere, including on cards; use surface alpha.
- **Don't** use grey for secondary text; use the label hue at lower alpha.
- **Don't** add a custom font or a font file.
