// The menu's stop-protection pane: pause for 1–3 hours, or turn off for this session.
// Port of ContentStopProtection.vue.

import SwiftUI

struct MenuStopProtectionPane: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                SectionTitle(text: model.t(StopStrings.stopFor))
                HStack(spacing: 8) {
                    ForEach(StopStrings.hours, id: \.0) { hours, label in
                        Button(model.t(label)) {
                            model.pauseProtection(hours: hours)
                            model.windows?.closeMenu()
                        }
                        .glassButton(.quiet, size: .large, fullWidth: true)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                GlassGroup {
                    GlassRowButton(title: model.t(StopStrings.turnOffContent), destructive: true) {
                        model.quit()
                    }
                }
                Footnote(text: model.t(StopStrings.turnOffInfo))
            }
        }
    }
}
