import Foundation

/// One executable proof of one requirement leaf. The id is the spec's dotted
/// number; the coverage gate is what guarantees it exists and is claimed once.
struct RequirementCase {
    let id: String
    let verify: () throws -> Void

    init(id: String, verify: @escaping () throws -> Void) {
        self.id = id
        self.verify = verify
    }
}

struct RequirementFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: Bool, _ message: @autoclosure () -> String) throws {
    if !condition { throw RequirementFailure(description: message()) }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ label: String) throws {
    if actual != expected {
        throw RequirementFailure(description: "\(label): expected \(expected), got \(actual)")
    }
}

func expectNil<T>(_ actual: T?, _ label: String) throws {
    if let actual { throw RequirementFailure(description: "\(label): expected nothing, got \(actual)") }
}
