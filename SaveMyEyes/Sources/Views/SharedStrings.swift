// Strings shared by the menu panes and the cover's floating cards.

import Foundation

/// Legacy settingsDict: both settings forms.
enum SettingsStrings {
    static let settings = L("Settings", "Ustawienia")
    static let breaks = L("Breaks", "Przerwy")
    static let shortEvery = L("Take a short break every", "Zrób krótką przerwę co")
    static let shortLast = L("Short break will last", "Krótka przerwa będzie trwała")
    static let longEvery = L("Take a long break every", "Zrób długą przerwę co")
    static let longLast = L("Long break will last", "Długa przerwa będzie trwała")
    static let soundUi = L("Play a sound when breaks start and end", "Odtwarzaj dźwięki")
    static let language = L("Language", "Język")
    static let createdBy = L("Created by", "Stworzona przez")
    static let author = L("Ammadeo", "Amadeusza Chomiaka")
    static let thanksTo = L("Thanks to", "Dzięki")
    static let thanksFor = L("for the awesome drawings", "za świetne rysunki")
    static let coffee = L("Buy me a coffee", "Zamów mi kawę")
    static let fixing = L("Settings saved with changes", "Poprawiam ustawienia")
    static let saved = L("Settings saved", "Zapisano ustawienia")
    static let saveFailed = L("Could not save settings", "Nie udało się zapisać ustawień")
    static let revert = L("Revert", "Cofnij")

    static let authorURL = "https://ammadeo.dev"
    static let undrawURL = "https://undraw.co/"
    static let coffeeURL = "https://buymeacoffee.com/ammadeo"
}

/// Legacy useStopProtection: the menu pane and the cover card.
enum StopStrings {
    static let title = L("Stop protection", "Wstrzymaj ochronę")
    static let stopFor = L("Stop protection for", "Wstrzymaj ochronę na")
    static let turnOffTitle = L("Turn off protection", "Wyłącz ochronę")
    static let turnOffContent = L("Turn off for this session", "Wyłącz podczas tej sesji")
    static let turnOffInfo = L("Save My Eyes starts again the next time you log in", "Aplikacja uruchomi się, gdy ponownie włączysz komputer")
    static let hours: [(Int, L)] = [
        (1, L("1 hour", "1 godzinę")),
        (2, L("2 hours", "2 godziny")),
        (3, L("3 hours", "3 godziny")),
    ]
}

extension HumanDuration {
    /// Polish accusative after "przez" / "temu" / "już": "1 minuta" → "1 minutę".
    static func accusative(_ text: String, lang: Lang) -> String {
        guard lang == .pl else { return text }
        return text
            .replacingOccurrences(of: "sekunda", with: "sekundę")
            .replacingOccurrences(of: "minuta", with: "minutę")
            .replacingOccurrences(of: "godzina", with: "godzinę")
    }
}
