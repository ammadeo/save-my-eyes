// Blank cover on every other display: a centred caption and the exit button bottom-right.
// Port of BlankView.vue + BlankBreakButton.vue.

import SwiftUI

private enum T {
    static let waiting = L("Wait for break to end", "Poczekaj na koniec przerwy")
    static let finished = L("Break has ended", "Przerwa zakończyła się")
    static let finish = L("Finish this break", "Zakończ przerwę")
    static let skip = L("Skip this break", "Pomiń przerwę")
}

struct BlankCoverView: View {
    let model: AppModel
    /// Tells the window where the exit button is (escape hatch, `EscapeRules`).
    var beacon: SkipBeacon?
    @State private var finished = false

    var body: some View {
        GeometryReader { geo in
            let pad = Theme.Space.cover(width: geo.size.width)
            ZStack {
                VStack(spacing: 12) {
                    HeaderTitle(model: model)
                    Text(model.t(finished ? T.finished : T.waiting))
                        .font(.smeLargeTitle)
                        .foregroundStyle(Theme.label)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button { model.exitBreak() } label: {
                    IconLabel(text: model.t(finished ? T.finish : T.skip), icon: finished ? "checkmark" : "forward.end.fill")
                }
                .glassButton(finished ? .primary : .quiet, size: .large)
                .reportsSkipButton(to: beacon, model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .padding(pad)
        }
        .onAppear { finished = model.breakEnded }
        .onChange(of: model.breakEndedCount) { finished = true }
    }
}
