// The groups both settings forms share (menu pane, cover card): four break sliders, and
// sounds + language.

import SwiftUI

struct BreakSlidersGroup: View {
    let model: AppModel
    @Bindable var form: SettingsForm

    var body: some View {
        let min = model.t(Strings.minutesSuffix)
        let everyMin = Swift.max(1, form.draft.every / 60)
        GlassGroup {
            SliderRow(label: model.t(SettingsStrings.shortEvery), value: $form.draft.every,
                      range: SettingsFormRules.everyMin, scale: 60, suffix: min)
            GroupDivider()
            SliderRow(label: model.t(SettingsStrings.shortLast), value: $form.draft.shortLast,
                      range: SettingsFormRules.shortLastSec, suffix: model.t(Strings.secondsSuffix))
            GroupDivider()
            SliderRow(label: model.t(SettingsStrings.longEvery), value: $form.draft.longEvery,
                      range: everyMin...SettingsFormRules.longEveryMaxMin, step: everyMin, scale: 60, suffix: min)
            GroupDivider()
            SliderRow(label: model.t(SettingsStrings.longLast), value: $form.draft.longLast,
                      range: SettingsFormRules.longLastMin, scale: 60, suffix: min)
        }
    }
}

struct SoundsLanguageGroup: View {
    let model: AppModel
    @Bindable var form: SettingsForm

    var body: some View {
        GlassGroup {
            SwitchRow(label: model.t(SettingsStrings.soundUi), isOn: $form.draft.soundsUi)
            GroupDivider()
            GlassRow {
                Text(model.t(SettingsStrings.language)).frame(maxWidth: .infinity, alignment: .leading)
                Picker(model.t(SettingsStrings.language), selection: $form.draft.lang) {
                    Text("English").tag(Lang.en)
                    Text("Polski").tag(Lang.pl)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
            }
        }
    }
}

/// Revert + Save, disabled until something changed.
struct SettingsActions: View {
    let model: AppModel
    let form: SettingsForm
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(model.t(SettingsStrings.revert)) { form.reset() }
                .glassButton(.quiet)
                .disabled(!form.changed)
            Button(model.t(Strings.settingsSave), action: onSave)
                .glassButton(.primary)
                .disabled(!form.changed)
                .keyboardShortcut(.defaultAction)
        }
    }
}
