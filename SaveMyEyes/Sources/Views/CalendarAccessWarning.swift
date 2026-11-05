// The persistent warning shown while "Don't break during meetings" is on but Save My Eyes
// cannot read the calendar (`CalendarStatus.needsAccess`): in the menu's main pane and in
// the Meetings settings section. Inline, never a modal, and it stays until access is back or
// the switch is turned off. Its re-enable button is, with the switch itself, the only thing
// that asks macOS for access.

import SwiftUI

private enum T {
    static let title = L("Breaks aren't held during meetings", "Przerwy nie czekają na koniec spotkań")
    static let detail = L("Save My Eyes can't read your calendar.", "Save My Eyes nie może odczytać kalendarza.")
    static let allow = L("Allow…", "Zezwól…")
    static let openSettings = L("Open Privacy Settings…", "Otwórz ustawienia prywatności…")
    static let turnOff = L("Turn off", "Wyłącz")
    static let turnOffHint = L("Turns off Don't break during meetings", "Wyłącza Bez przerw w trakcie spotkań")
}

/// Row content without its own group: the main pane wraps it in a `GlassGroup`, the
/// settings section puts it in the Meetings group under the switch.
struct CalendarAccessWarning: View {
    let model: AppModel
    /// Set by the parent while its own calendar action is in flight.
    var disabled = false
    @State private var busy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.warning)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.t(T.title))
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.warning)
                    Text(model.t(T.detail))
                        .font(.smeFootnote)
                        .foregroundStyle(Theme.labelSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.smeBody)
            .accessibilityElement(children: .combine)
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Button(model.t(T.turnOff)) { run { _ = await model.setCalendarEnabled(false) } }
                    .glassButton(.quiet)
                    .accessibilityHint(model.t(T.turnOffHint))
                Button(model.t(model.calendarStatus.access == .notDetermined ? T.allow : T.openSettings)) {
                    run { await model.restoreCalendarAccess() }
                }
                .glassButton(.quiet)
            }
            .disabled(busy || disabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func run(_ action: @escaping @MainActor () async -> Void) {
        busy = true
        Task { @MainActor in
            await action()
            busy = false
        }
    }
}
