import XCTest

/// The entry point every kind's cases run through: one test per kind, each
/// executing the kind's generated manifest. A kind is not "registered" until it
/// appears here — the coverage gate checks that too.
final class RequirementsTests: XCTestCase {
    func testLogicRequirements() { run(LogicManifest.cases) }
    func testBehaviorRequirements() { run(BehaviorManifest.cases) }
    func testScreenRequirements() { run(ScreenManifest.cases) }
    func testSagaRequirements() { run(SagaManifest.cases) }

    private func run(_ cases: [RequirementCase]) {
        for requirement in cases {
            do {
                try requirement.verify()
            } catch {
                XCTFail("requirement \(requirement.id) failed: \(error)")
            }
        }
    }
}
