// Bottom-left of the cover: one random break idea per break type, or after a finished long
// break the "Like what you see?" donation card. Port of IndexIdea.vue + ContentDonation.vue.

import SwiftUI

private enum T {
    static let title = L("Try this break idea", "Zainspiruj się")
    static let donationAlt = L("Spread love", "Podziel się miłością")
    static let donationTitle = L("Like what you see?", "Podoba Ci się aplikacja?")
    static let donationText = L("Consider supporting development of this project", "Rozważ wsparcie rozwoju tego projektu")
    static let donationLink = L("Buy me a coffee", "Zamów mi kawę")
    static let donationNote = L("Will open your default browser", "Otworzy się w Twojej przeglądarce")
}

struct Idea {
    let title: L
    let image: String
    let alt: L
    let content: L

    static let long: [Idea] = [
        Idea(title: L("Do some exercises", "Poćwicz chwilę"), image: "workout",
             alt: L("Woman dancing", "Tańcząca kobieta"),
             content: L("A few minutes of workout will help you relax from sitting position",
                        "Kilka minut ćwiczeń pomoże ci się zrelaksować")),
        Idea(title: L("Go outside", "Wyjdź na świeże powietrze"), image: "outside",
             alt: L("Woman walk through a forest", "Kobieta idzie przez las"),
             content: L("Go out to a park or a forest. Being close to nature will help you relax",
                        "Pójdź na spacer do parku. Kontakt z naturą pomoże ci się zrelaksować")),
        Idea(title: L("Relax a bit", "Zrelaksuj się"), image: "mindfulness",
             alt: L("Woman meditating in front of ancient temple", "Kobieta medytuje przed świątynią"),
             content: L("Do what you do to relax. It could be drinking tea, meditating or whatever you like. But remember not to use your phone or computer now",
                        "Zrób to co zwykle, gdy potrzebujesz się odprężyć. Przykładowo wypij herbatę, bądź pomedytuj. Pamiętaj, żeby nie używać do tego komputera, ani telefonu")),
    ]

    static let short: [Idea] = [
        Idea(title: L("Look out the window", "Wyjrzyj przez okno"), image: "window",
             alt: L("Woman looks out the window", "Kobieta spogląda przez okno"),
             content: L("Look far away through a window to help your eyes relax",
                        "Patrzenie w dal pomoże Ci uniknąć krótkowzroczności")),
        Idea(title: L("Look at plants", "Popatrz na rośliny"), image: "plants",
             alt: L("Man is sitting in front of flowers", "Mężczyzna siedzi przy kwiatach"),
             content: L("Green plants will help relax your eyes",
                        "Spojrzenie na rośliny pomoże Ci zrelaksować oczy i odprężyć umysł")),
        Idea(title: L("Blink your eyes", "Pomrugaj oczami"), image: "blink",
             alt: L("Man looks at the darkness", "Mężczyzna patrzy w ciemność"),
             content: L("Blink a few times to clean your eyes", "Mrugnij kilka razy, aby oczyścić oczy")),
    ]

    static func random(long: Bool) -> Idea { (long ? Idea.long : Idea.short).randomElement()! }
}

struct IdeaCard: View {
    let model: AppModel
    let isLong: Bool
    let finished: Bool
    let forceCloseLock: Bool
    let imageHeight: CGFloat

    @State private var idea: Idea
    @State private var appeared = false
    @State private var coffeeOpened = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: AppModel, isLong: Bool, finished: Bool, forceCloseLock: Bool, imageHeight: CGFloat) {
        self.model = model
        self.isLong = isLong
        self.finished = finished
        self.forceCloseLock = forceCloseLock
        self.imageHeight = imageHeight
        _idea = State(initialValue: Idea.random(long: isLong))
    }

    private var showDonation: Bool { isLong && finished }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.t(T.title))
                .font(.smeFootnote)
                .foregroundStyle(Theme.labelSecondary)
                .padding(.leading, 16)
                .opacity(showDonation ? 0 : 1)
                .animation(.linear(duration: 0.1), value: showDonation)
            ZStack(alignment: .bottomLeading) {
                if showDonation {
                    RaisedCard { donation }
                        .transition(swapIn)
                } else {
                    RaisedCard { ideaContent }
                        .transition(swapOut)
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.1) : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.32), value: showDonation)
            .offset(y: appeared || reduceMotion ? 0 : imageHeight * 2)
            .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: 680, alignment: .leading)
        .onAppear {
            // A calm, decelerating entrance.
            withAnimation(reduceMotion ? .easeInOut(duration: 0.1) : .timingCurve(0.16, 1, 0.3, 1, duration: 0.6).delay(0.15)) {
                appeared = true
            }
        }
    }

    private var swapIn: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }
    private var swapOut: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity))
    }

    private var ideaContent: some View {
        HStack(spacing: 20) {
            IdeaImage(name: idea.image, alt: model.t(idea.alt), height: imageHeight)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.t(idea.title))
                    .font(.smeTitle2)
                    .foregroundStyle(Theme.label)
                Text(model.t(idea.content))
                    .font(.smeBody)
                    .foregroundStyle(Theme.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 340, alignment: .leading)
        }
    }

    private var donation: some View {
        HStack(spacing: 20) {
            IdeaImage(name: "appreciation", alt: model.t(T.donationAlt), height: imageHeight)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.t(T.donationTitle))
                    .font(.smeTitle2)
                    .foregroundStyle(Theme.label)
                Text(model.t(T.donationText))
                    .font(.smeBody)
                    .foregroundStyle(Theme.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    guard !coffeeOpened else { return }
                    coffeeOpened = true
                    model.openURL(SettingsStrings.coffeeURL)
                    model.endBreak()
                } label: {
                    IconLabel(text: model.t(T.donationLink), icon: "cup.and.saucer")
                }
                .glassButton(.quiet, size: .large)
                .disabled(forceCloseLock)
                .padding(.top, 8)
                Text(model.t(T.donationNote))
                    .font(.smeFootnote)
                    .foregroundStyle(Theme.labelSecondary)
                    .padding(.top, 4)
            }
            .frame(maxWidth: 340, alignment: .leading)
        }
    }
}

/// One of the unDraw illustrations from the bundle's `Images/` folder.
struct IdeaImage: View {
    let name: String
    let alt: String
    let height: CGFloat

    var body: some View {
        if let image = BundleImage.load(name) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(image.size, contentMode: .fit)
                .frame(height: height)
                .accessibilityLabel(alt)
        } else {
            Color.clear.frame(width: height, height: height).accessibilityHidden(true)
        }
    }
}
