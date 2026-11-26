// Bottom-left of the cover: the break idea the model drew as the break started
// (`AppModel.breakIdea`, from the idea sets in `Core/Ideas`), or after a finished long break
// the "Save My Eyes is free" donation card. Port of IndexIdea.vue + ContentDonation.vue.

import SwiftUI

private enum T {
    static let title = L("Try this break idea", "Pomysł na przerwę")
    static let donationAlt = L("Three small creatures around a big heart", "Trzy małe stworki wokół dużego serca")
    static let donationTitle = L("Save My Eyes is free", "Save My Eyes jest za darmo")
    static let donationText = L("If these breaks help you, you can support its development", "Jeśli te przerwy Ci pomagają, możesz wesprzeć rozwój aplikacji")
    static let donationLink = L("Buy me a coffee", "Postaw mi kawę")
    static let donationNote = L("Opens in your browser", "Otworzy się w Twojej przeglądarce")
}

struct IdeaCard: View {
    let model: AppModel
    /// `nil` when no idea set had one for this break: the card is left out.
    let idea: Idea?
    let isLong: Bool
    let finished: Bool
    let forceCloseLock: Bool
    let imageHeight: CGFloat

    @State private var appeared = false
    @State private var coffeeOpened = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: AppModel, idea: Idea?, isLong: Bool, finished: Bool, forceCloseLock: Bool, imageHeight: CGFloat) {
        self.model = model
        self.idea = idea
        self.isLong = isLong
        self.finished = finished
        self.forceCloseLock = forceCloseLock
        self.imageHeight = imageHeight
    }

    private var showDonation: Bool { isLong && finished }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.t(T.title))
                .font(.smeFootnote)
                .foregroundStyle(Theme.labelSecondary)
                .padding(.leading, 16)
                .opacity(showDonation || idea == nil ? 0 : 1)
                .animation(.linear(duration: 0.1), value: showDonation)
            ZStack(alignment: .bottomLeading) {
                if showDonation {
                    RaisedCard { donation }
                        .transition(swapIn)
                } else if let idea {
                    RaisedCard { ideaContent(idea) }
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

    private func ideaContent(_ idea: Idea) -> some View {
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
