import XCTest
@testable import SaveMyEyes

/// Idea sets: each set's own rule decides whether it fits, the pool for a break is every
/// fitting set's ideas, and the model draws from it as the break starts. Ideas are told apart
/// by their illustration, so rewording the copy does not touch these tests.
@MainActor
final class IdeasTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var dir: URL!

    override func setUp() async throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("sme-ideas-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func idea(_ name: String) -> Idea {
        Idea(title: L(verbatim: name), image: name, alt: L(verbatim: name), content: L(verbatim: name))
    }

    private func pool(_ sets: IdeaSets, long: Bool, now: Date) -> Set<String> {
        Set(sets.available(now: now).flatMap { long ? $0.long : $0.short }.map(\.image))
    }

    private func builtIn(sunIsUp: Bool?) -> IdeaSets {
        IdeaSets([.always, .day(sunIsUp: { _ in sunIsUp }), .night(sunIsUp: { _ in sunIsUp })])
    }

    // MARK: The mechanism

    func testThePoolIsEveryFittingSetsIdeas() {
        let sets = IdeaSets([
            IdeaSet(name: "a", isAvailable: { _ in true }, long: [idea("a-long")], short: [idea("a-short")]),
            IdeaSet(name: "b", isAvailable: { _ in false }, long: [idea("b-long")], short: [idea("b-short")]),
            IdeaSet(name: "c", isAvailable: { _ in true }, long: [idea("c-long")]),
        ])
        XCTAssertEqual(sets.available(now: now).map(\.name), ["a", "c"])
        XCTAssertEqual(pool(sets, long: true, now: now), ["a-long", "c-long"])
        XCTAssertEqual(pool(sets, long: false, now: now), ["a-short"])
        for _ in 0..<50 {
            XCTAssertNotEqual(sets.pick(long: true, now: now)?.image, "b-long", "a set that does not fit is never drawn from")
        }
        XCTAssertEqual(sets.pick(long: false, now: now)?.image, "a-short")
    }

    func testASetIsAskedAboutTheMomentTheBreakStarts() {
        var asked: [Date] = []
        let sets = IdeaSets([IdeaSet(name: "a", isAvailable: { asked.append($0); return true }, long: [idea("a")])])
        _ = sets.pick(long: true, now: now)
        XCTAssertEqual(asked, [now])
    }

    func testNoIdeaWhenNothingFits() {
        XCTAssertNil(IdeaSets([]).pick(long: true, now: now))
        let longOnly = IdeaSets([IdeaSet(name: "a", isAvailable: { _ in true }, long: [idea("a")])])
        XCTAssertNil(longOnly.pick(long: false, now: now), "a fitting set with no idea for this kind of break")
    }

    // MARK: The built-in sets

    func testDayAndNightGoByTheSun() {
        XCTAssertEqual(builtIn(sunIsUp: true).available(now: now).map(\.name), ["always", "day"])
        XCTAssertEqual(builtIn(sunIsUp: false).available(now: now).map(\.name), ["always", "night"])
        XCTAssertEqual(builtIn(sunIsUp: nil).available(now: now).map(\.name), ["always"], "an unknown sun leaves the ideas that always fit")
    }

    func testTheSunIsAskedAboutTheMomentTheBreakStarts() {
        var asked: [Date] = []
        let day = IdeaSet.day(sunIsUp: { asked.append($0); return true })
        XCTAssertTrue(day.isAvailable(now))
        XCTAssertEqual(asked, [now])
    }

    /// Issue #41: going outside is not suggested after sunset.
    func testGoingOutsideIsOnlySuggestedInDaylight() {
        XCTAssertTrue(pool(builtIn(sunIsUp: true), long: true, now: now).contains("outside"))
        XCTAssertFalse(pool(builtIn(sunIsUp: false), long: true, now: now).contains("outside"))
        XCTAssertFalse(pool(builtIn(sunIsUp: nil), long: true, now: now).contains("outside"))
    }

    /// After dark the blinds may be down, so nothing sends the user to the window.
    func testTheWindowIsOnlySuggestedInDaylight() {
        XCTAssertTrue(pool(builtIn(sunIsUp: true), long: false, now: now).contains("window"))
        for long in [true, false] {
            XCTAssertFalse(pool(builtIn(sunIsUp: false), long: long, now: now).contains("window"))
        }
    }

    func testEveryBreakHasAnIdeaWhateverTheSun() {
        for sun in [true, false, nil] as [Bool?] {
            for long in [true, false] {
                XCTAssertNotNil(builtIn(sunIsUp: sun).pick(long: long, now: now), "sun \(String(describing: sun)), long \(long)")
            }
        }
    }

    func testEveryIllustrationIsInTheBundle() {
        let ideas = [IdeaSet.always, .day(sunIsUp: { _ in nil }), .night(sunIsUp: { _ in nil })].flatMap { $0.long + $0.short }
        XCTAssertFalse(ideas.isEmpty)
        for idea in ideas {
            XCTAssertNotNil(BundleImage.load(idea.image), idea.image)
        }
    }

    /// Every idea has a drawing of its own, so two breaks in a row never show the same picture
    /// under different words.
    func testNoTwoIdeasShareAnIllustration() {
        let images = [IdeaSet.always, .day(sunIsUp: { _ in nil }), .night(sunIsUp: { _ in nil })].flatMap { $0.long + $0.short }.map(\.image)
        XCTAssertEqual(images.count, Set(images).count, "\(images)")
    }

    // MARK: The model

    /// The idea on the cover is drawn when a break starts, from the sets the model was given.
    func testTheModelDrawsAnIdeaAsABreakStarts() throws {
        let url = dir.appendingPathComponent("settings.json")
        try Settings(lang: .en).save(to: url)
        var sunIsUp = true
        let sets = IdeaSets([
            IdeaSet(name: "day", isAvailable: { _ in sunIsUp }, long: [idea("day")]),
            IdeaSet(name: "night", isAvailable: { _ in !sunIsUp }, long: [idea("night")]),
        ])
        let model = AppModel(settingsURL: url, calendar: FakeCalendar(), devices: FakeDevices(), ideas: sets)
        XCTAssertNil(model.breakIdea, "nothing is drawn before a break")

        model.startLongBreakNow()
        XCTAssertEqual(model.breakIdea?.image, "day")

        sunIsUp = false
        XCTAssertEqual(model.breakIdea?.image, "day", "the idea stays for the whole break")
        model.endBreak()
        model.startLongBreakNow()
        XCTAssertEqual(model.breakIdea?.image, "night", "the next break asks again")
        model.endBreak()
    }
}
