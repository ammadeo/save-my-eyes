// The before-break card, top-right of the primary display: "short break will start in 5
// seconds" with a progress bar, Wait, then Skip / Start. Auto-starts after 5 s unless the
// user waits. Port of ContentBeforeBreak.vue + BeforeBreakView.vue. No background: the
// window paints the glass with 18 pt corners.

import AppKit
import SwiftUI

private enum T {
    // Polish is kept short: both buttons must fit the 360 pt card side by side.
    static let start = L("start this break", "zacznij przerwę")
    static let wait = L("wait", "zaczekaj")
    static let skip = L("skip this break", "pomiń")
    static let base = L("will start", "zacznie się")
    static let statusWaiting = L("when you're ready", "kiedy zechcesz")
    static let statusIn = L("in", "za")
    static let waitingPrefix = L("You've been waiting for", "Czekasz już")
    static let autoStart = L("Time until the break starts", "Czas do rozpoczęcia przerwy")
}

struct BeforeBreakView: View {
    let model: AppModel
    var autoStartSecs: TimeInterval = 5

    @State private var shownAt = Date()
    @State private var waiting = false
    @State private var waitingFrom: Date?
    @State private var started = false
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: shownAt, by: 0.25)) { context in
            card(now: context.date)
        }
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)
        .task {
            try? await Task.sleep(for: .seconds(autoStartSecs))
            if !waiting { start() }
        }
        .task(id: waiting) {
            // After a minute of waiting the card breathes a faint sage tint over the glass.
            guard waiting, !reduceMotion else { return }
            try? await Task.sleep(for: .seconds(60))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private func card(now: Date) -> some View {
        let isLong = model.breakState.isLong
        let elapsed = now.timeIntervalSince(shownAt)
        let fraction = min(1, max(0, elapsed / autoStartSecs))
        let secsLeft = max(1, Int((autoStartSecs - elapsed).rounded(.up)))
        let name = model.t(isLong ? Strings.breakLong : Strings.breakShort)
        let tail = waiting ? model.t(T.statusWaiting)
            : "\(model.t(T.statusIn)) \(HumanDuration.formatted(seconds: secsLeft, lang: model.lang))"
        let status = "\(name) \(model.t(T.base)) \(tail)".capitalizedFirst

        return HStack(alignment: .top, spacing: 12) {
            AppIconImage()
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(model.t(Strings.title))
                    .font(.smeHeadline)
                    .accessibilityAddTraits(.isHeader)
                Text(status)
                    .padding(.top, 2)
                    .fixedSize(horizontal: false, vertical: true)
                if let info = waitingInfo(now: now) {
                    (Text("\(model.t(T.waitingPrefix)) ") + Text(info).fontWeight(.medium))
                        .foregroundStyle(Theme.labelSecondary)
                        .padding(.top, 2)
                }
                HStack(spacing: 8) {
                    if !waiting {
                        GlassProgressBar(fraction: fraction, height: 4, label: model.t(T.autoStart), animated: !reduceMotion)
                            .frame(maxWidth: .infinity)
                    } else {
                        Spacer(minLength: 0)
                        Button { model.skipBreak() } label: { Text(model.t(T.skip).capitalizedFirst) }
                            .glassButton(.quiet)
                    }
                    Button { onPrimary() } label: {
                        Text((waiting ? model.t(T.start) : model.t(T.wait)).capitalizedFirst)
                    }
                    .glassButton(waiting ? .primary : .quiet)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.smeBody)
        .foregroundStyle(Theme.label)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous)
                .fill(Theme.accent.opacity(pulse ? 0.14 : 0))
        }
    }

    /// "2 minutes" once at least a minute has passed; refreshed by the minute.
    private func waitingInfo(now: Date) -> String? {
        guard let waitingFrom else { return nil }
        let secs = Int(now.timeIntervalSince(waitingFrom))
        guard secs >= 60 else { return nil }
        let info = HumanDuration.formatted(seconds: secs / 60 * 60, lang: model.lang)
        // "Czekasz już minutę", not "1 minuta".
        if model.lang == .pl, info.hasPrefix("1 minuta") { return "minutę" }
        return info
    }

    private func onPrimary() {
        if waiting { return start() }
        waiting = true
        waitingFrom = Date()
    }

    private func start() {
        guard !started else { return }
        started = true
        model.startBreak()
    }
}

/// The app icon from the bundle (`Images/app-icon.png`), else the running app's icon.
struct AppIconImage: View {
    var body: some View {
        let image = BundleImage.load("app-icon", "png") ?? NSApp.applicationIconImage ?? NSImage()
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
    }
}
