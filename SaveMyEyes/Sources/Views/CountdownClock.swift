// The cover's info line and countdown (TimerInfo.vue, TimerClock.vue).

import SwiftUI

private enum T {
    static let shortFinished = L("short break has ended", "krótka przerwa zakończyła się")
    static let longFinished = L("long break has ended", "długa przerwa zakończyła się")
    static let shortStarted = L("take a short break for", "krótka przerwa przez")
    static let longStarted = L("take a long break for", "długa przerwa przez")
    static let ago = L("ago", "temu")
    static let autoFinish = L("Ends by itself", "Zakończy się sama")
    static let progress = L("Break progress", "Postęp przerwy")
    static let left = L("left", "zostało")
}

/// "Take a short break for 20 seconds", then "Short break has ended 2 minutes ago".
struct TimerInfo: View {
    let model: AppModel
    let isLong: Bool
    let start: Date
    let end: Date
    let finished: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            Text(info(now: context.date).capitalizedFirst)
                .font(.smeLargeTitle)
                .foregroundStyle(Theme.label)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 560, alignment: .leading)
        }
    }

    private func info(now: Date) -> String {
        let lang = model.lang
        if finished {
            let base = model.t(isLong ? T.longFinished : T.shortFinished)
            let mins = Int(now.timeIntervalSince(end) / 60)
            guard mins >= 1 else { return base }
            let ago = HumanDuration.accusative(HumanDuration.between(end, now, lang: lang), lang: lang)
            return "\(base) \(ago) \(model.t(T.ago))"
        }
        let length = HumanDuration.accusative(HumanDuration.between(start, end, lang: lang), lang: lang)
        return "\(model.t(isLong ? T.longStarted : T.shortStarted)) \(length)"
    }
}

/// "mm : ss" in the display style over a wide sage progress bar; fades to 0.25 when done.
struct CountdownClock: View {
    let model: AppModel
    let start: Date
    let end: Date
    /// Short breaks close themselves when the time is up; say so under the bar.
    let autoFinish: Bool
    /// Cover width, for the clamp(56, 9vw, 96) display size.
    let coverWidth: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: start, by: 0.25)) { context in
            clock(now: context.date)
        }
    }

    private func clock(now: Date) -> some View {
        let total = max(0, end.timeIntervalSince(start))
        let remaining = max(0, end.timeIntervalSince(now))
        let fraction = total > 0 ? (total - remaining) / total : 1
        let secs = Int(remaining.rounded(.up))
        let text = String(format: "%02d : %02d", secs / 60, secs % 60)
        let spoken = "\(secs / 60) \(model.t(Strings.minutesSuffix)) \(secs % 60) \(model.t(Strings.secondsSuffix)) \(model.t(T.left))"
        let size = min(max(coverWidth * 0.09, 56), 96)
        let done = remaining <= 0

        return VStack(alignment: .leading, spacing: 24) {
            Text(text)
                .font(.smeDisplay(width: coverWidth))
                .tracking(-0.02 * size)
                .foregroundStyle(Theme.label)
                .lineLimit(1)
                .fixedSize()
                .accessibilityLabel(spoken)
                .accessibilityAddTraits(.updatesFrequently)
            VStack(alignment: .leading, spacing: 8) {
                GlassProgressBar(fraction: fraction, height: 8, label: model.t(T.progress), animated: !reduceMotion)
                if autoFinish {
                    Text(model.t(T.autoFinish))
                        .font(.smeFootnote)
                        .foregroundStyle(Theme.labelSecondary)
                }
            }
        }
        .frame(maxWidth: 680, alignment: .leading)
        .opacity(done ? 0.25 : 1)
        .animation(.easeOut(duration: 1), value: done)
    }
}
