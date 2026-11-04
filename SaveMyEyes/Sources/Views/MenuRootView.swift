// The menu popover: a toolbar strip with the pane title (and Back) over one of three panes.
// Port of src/views/MenuView.vue. 400 pt wide; the height follows the pane so the hosting
// popover sizes itself. Escape closes the menu.

import SwiftUI

private enum T {
    static let settings = L("Settings", "Ustawienia")
    static let stopProtection = L("Stop protection", "Wstrzymaj ochronę")
    static let back = L("Back", "Wstecz")
}

struct MenuRootView: View {
    let model: AppModel
    @State private var pane: MenuPane
    /// Direction of the last pane change (forward = deeper).
    @State private var forward = true
    @AccessibilityFocusState private var titleFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: AppModel, initialPane: MenuPane = .menu) {
        self.model = model
        _pane = State(initialValue: initialPane)
    }

    private var title: String {
        switch pane {
        case .menu: model.t(Strings.title)
        case .settings: model.t(T.settings)
        case .stopProtection: model.t(T.stopProtection)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            ZStack(alignment: .top) {
                paneView
                    .id(pane)
                    .transition(paneTransition)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .clipped()
        }
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Theme.label)
        .font(.smeBody)
        .onExitCommand { model.windows?.closeMenu() }
    }

    private var toolbar: some View {
        ZStack {
            Text(title)
                .font(.smeHeadline)
                .foregroundStyle(Theme.label)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)
            HStack {
                if pane != .menu {
                    Button { open(.menu) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 28, height: 24)
                    }
                    .glassButton(.plain, hPadding: 0)
                    .accessibilityLabel(model.t(T.back))
                    .keyboardShortcut("[", modifiers: .command)
                }
                Spacer()
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    @ViewBuilder private var paneView: some View {
        switch pane {
        case .menu:
            MenuMainPane(model: model, open: { open($0) })
        case .settings:
            MenuSettingsPane(model: model)
        case .stopProtection:
            MenuStopProtectionPane(model: model)
        }
    }

    private var paneTransition: AnyTransition {
        if reduceMotion { return .opacity }
        let shift: CGFloat = 24
        return .asymmetric(
            insertion: .offset(x: forward ? shift : -shift).combined(with: .opacity),
            removal: .offset(x: forward ? -shift : shift).combined(with: .opacity))
    }

    /// Focus follows the pane like a macOS navigation stack: forward lands on the new title.
    private func open(_ next: MenuPane) {
        // Set the direction first so the leaving pane picks up the right transition.
        forward = next != .menu
        Task { @MainActor in
            withAnimation(reduceMotion ? .easeInOut(duration: 0.1) : .timingCurve(0.25, 0.8, 0.25, 1, duration: 0.22)) {
                pane = next
            }
            if next != .menu { titleFocused = true }
        }
    }
}
