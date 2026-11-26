// Break ideas, kept in sets. A set carries its own rule for when it fits (`isAvailable`), and
// as a break starts the model asks every set and draws the idea on the cover from the ones
// that say they fit right then (`IdeaSets.pick`). A new kind of set (the weather, the season,
// a setting, the day of the week) is one more `IdeaSet` in `IdeaSets.builtIn` with its own
// rule; the model, the scheduler and the views do not change.

import Foundation

/// One break idea: what the card on the cover shows.
struct Idea: Equatable, Sendable {
    let title: L
    /// An illustration from the bundle's `Images/` folder.
    let image: String
    let alt: L
    let content: L
}

/// Ideas that belong together, and the rule that says when they fit.
struct IdeaSet {
    /// For the log.
    let name: String
    /// Whether these ideas fit a break starting at the given moment. Asked once per break, as
    /// it starts, so the rule may read whatever it needs then (the clock, the sun, a setting).
    let isAvailable: (Date) -> Bool
    /// Ideas for a long break and for a short one. Either may be empty.
    var long: [Idea] = []
    var short: [Idea] = []
}

/// Every idea set as one: the pool for a break is the ideas of all the sets that fit it.
struct IdeaSets {
    let sets: [IdeaSet]

    init(_ sets: [IdeaSet]) {
        self.sets = sets
    }

    /// The sets that fit a break starting at `now`.
    func available(now: Date) -> [IdeaSet] {
        sets.filter { $0.isAvailable(now) }
    }

    /// One idea for a break starting at `now`, each idea of each fitting set as likely as any
    /// other. `nil` when no fitting set has an idea for this kind of break.
    func pick(long: Bool, now: Date) -> Idea? {
        let fitting = available(now: now)
        let idea = fitting.flatMap { long ? $0.long : $0.short }.randomElement()
        Log.info("ideas", "sets that fit: \(fitting.map(\.name).joined(separator: ", ")); showing \(idea?.title.en ?? "nothing")")
        return idea
    }
}

// MARK: - The built-in sets

extension IdeaSets {
    /// The ideas the app ships with. `always` fits any break; `day` and `night` go by the sun
    /// where the Mac's time zone says the user is (`Sun`), and neither fits when that is
    /// unknown, which leaves `always`.
    static let builtIn = IdeaSets([
        .always,
        .day(sunIsUp: { Sun.isUp(at: $0) }),
        .night(sunIsUp: { Sun.isUp(at: $0) }),
    ])
}

extension IdeaSet {
    /// Fits any break, indoors, at any hour.
    static let always = IdeaSet(
        name: "always",
        isAvailable: { _ in true },
        long: [
            Idea(title: L("Do some exercises", "Poćwicz chwilę"), image: "workout",
                 alt: L("Woman dancing", "Tańcząca kobieta"),
                 content: L("A few minutes of movement gives your body a rest from sitting",
                            "Kilka minut ruchu pozwoli Twojemu ciału odpocząć od siedzenia")),
            Idea(title: L("Relax a bit", "Zrelaksuj się"), image: "mindfulness",
                 alt: L("Woman meditating in front of an ancient temple", "Kobieta medytuje przed świątynią"),
                 content: L("Do whatever relaxes you: drink tea, meditate. Just stay off your phone and computer",
                            "Zrób coś, co Cię odpręża: wypij herbatę, pomedytuj. Tylko bez telefonu i komputera")),
            Idea(title: L("Get a glass of water", "Napij się wody"), image: "water",
                 alt: L("Woman drinking through a straw", "Kobieta pije przez słomkę"),
                 content: L("Walk to the kitchen and pour yourself a glass. You stretch your legs on the way",
                            "Przejdź się do kuchni i nalej sobie szklankę. Przy okazji rozprostujesz nogi")),
            Idea(title: L("Stretch your neck and back", "Rozciągnij szyję i plecy"), image: "stretch",
                 alt: L("Woman standing on one leg with her hands joined above her head",
                        "Kobieta stoi na jednej nodze z dłońmi złączonymi nad głową"),
                 content: L("Stand up, reach for the ceiling, then slowly tilt your head to each side",
                            "Wstań, sięgnij rękami do sufitu, a potem powoli przechyl głowę na boki")),
            Idea(title: L("Move your whole body", "Rozruszaj całe ciało"), image: "movement",
                 alt: L("Woman doing a lunge on an exercise mat", "Kobieta robi wykrok na macie do ćwiczeń"),
                 content: L("Try a few lunges, squats and side bends, then shake out your arms and legs",
                            "Zrób kilka wykroków, przysiadów i skłonów w bok, a na koniec rozluźnij ręce i nogi")),
        ],
        short: [
            Idea(title: L("Look at plants", "Popatrz na rośliny"), image: "plants",
                 alt: L("Man sitting beside a potted plant", "Mężczyzna siedzi obok rośliny w doniczce"),
                 content: L("Green plants will help relax your eyes",
                            "Zielone rośliny pomogą Twoim oczom odpocząć")),
            Idea(title: L("Blink a few times", "Pomrugaj oczami"), image: "blink",
                 alt: L("Man standing before a large dark circle", "Mężczyzna stoi przed dużym ciemnym kołem"),
                 content: L("Blinking keeps your eyes from drying out", "Mrugnij kilka razy, żeby nawilżyć oczy")),
            Idea(title: L("Close your eyes", "Zamknij oczy"), image: "rest",
                 alt: L("Woman leaning back in a chair, away from her screen", "Kobieta odchylona na krześle, z dala od ekranu"),
                 content: L("Lean back and keep them closed until the break ends",
                            "Odchyl się na krześle i nie otwieraj ich do końca przerwy")),
            Idea(title: L("Look near, then far", "Spójrz blisko, potem daleko"), image: "spyglass",
                 alt: L("Person looking through a spyglass", "Osoba patrzy przez lunetę"),
                 content: L("Focus on your finger, then on the farthest thing you can see. Repeat a few times",
                            "Skup wzrok na palcu, a potem na najdalszej rzeczy, jaką widzisz. Powtórz kilka razy")),
            Idea(title: L("Drop your shoulders", "Rozluźnij ramiona"), image: "shoulders",
                 alt: L("Woman with one shoulder raised and the other lowered",
                        "Kobieta z jednym ramieniem uniesionym, a drugim opuszczonym"),
                 content: L("Roll them back a few times and let your neck loosen",
                            "Zrób nimi kilka krążeń do tyłu i rozluźnij szyję")),
        ]
    )

    /// Ideas that need daylight. Fits while the sun is up; `sunIsUp` answers `nil` when it
    /// cannot tell.
    static func day(sunIsUp: @escaping (Date) -> Bool?) -> IdeaSet {
        IdeaSet(
            name: "day",
            isAvailable: { sunIsUp($0) == true },
            long: [
                Idea(title: L("Go outside", "Wyjdź na świeże powietrze"), image: "outside",
                     alt: L("Woman walking through a forest", "Kobieta idzie przez las"),
                     content: L("Go out to a park or a forest. Being close to nature will help you relax",
                                "Wybierz się do parku albo do lasu. Kontakt z naturą pomoże Ci się odprężyć")),
            ],
            short: [
                Idea(title: L("Look out the window", "Wyjrzyj przez okno"), image: "window",
                     alt: L("Woman looking out the window", "Kobieta spogląda przez okno"),
                     content: L("Focus on something far away to let your eyes relax",
                                "Skup wzrok na czymś w oddali, żeby dać oczom odpocząć")),
                Idea(title: L("Open the window", "Otwórz okno"), image: "open-window",
                     alt: L("Woman with a dog in front of tall windows opened wide",
                            "Kobieta z psem przed wysokim, otwartym na oścież oknem"),
                     content: L("Let in some fresh air and look at something far away while you're there",
                                "Wpuść trochę świeżego powietrza i przy okazji popatrz na coś w oddali")),
            ]
        )
    }

    /// Ideas for after dark. Fits while the sun is down. Nothing here leans on the window:
    /// at night the blinds may be down.
    static func night(sunIsUp: @escaping (Date) -> Bool?) -> IdeaSet {
        IdeaSet(
            name: "night",
            isAvailable: { sunIsUp($0) == false },
            long: [
                Idea(title: L("Dim the lights", "Przygaś światło"), image: "lamp",
                     alt: L("Woman reading under a floor lamp", "Kobieta czyta pod lampą stojącą"),
                     content: L("Switch off the bright lamps for a few minutes and let your eyes rest in soft light",
                                "Zgaś na kilka minut mocne lampy i daj oczom odpocząć w łagodnym świetle")),
            ],
            short: [
                Idea(title: L("Look across the room", "Spójrz w głąb pokoju"), image: "room",
                     alt: L("Living room with a sofa, a floor lamp and a cat", "Salon z kanapą, lampą stojącą i kotem"),
                     content: L("Rest your eyes on the farthest thing in the room",
                                "Zatrzymaj wzrok na najdalszej rzeczy w pokoju")),
            ]
        )
    }
}
