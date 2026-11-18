import Foundation
import Testing
@testable import MageCore

@Suite struct PrimitivesTests {
    @Test func severitiesAreOrdered() {
        #expect(DiagnosticSeverity.note < .warning)
        #expect(DiagnosticSeverity.warning < .error)
        #expect([Diagnostic(code: DiagnosticCode("x"), severity: .warning, message: "m")].containsErrors == false)
        #expect([Diagnostic(code: DiagnosticCode("x"), severity: .error, message: "m")].containsErrors)
    }

    @Test(arguments: ["vapor", "fluent", "swift-nio", "vapor5", "a"])
    func acceptsValidAdapterIds(_ id: String) throws {
        #expect(try AdapterID(id).rawValue == id)
    }

    @Test(arguments: ["", "Vapor", "-vapor", "vapor-", "va--por", "va por", "1vapor", "vapör"])
    func rejectsInvalidAdapterIds(_ id: String) {
        #expect(throws: MageError.self) { try AdapterID(id) }
    }

    @Test func frameworkAndPersistenceAreIndependentAxes() throws {
        let vapor = AdapterDescriptor(id: try AdapterID("vapor"), kind: .framework, displayName: "Vapor")
        let fluent = AdapterDescriptor(id: try AdapterID("fluent"), kind: .persistence, displayName: "Fluent")
        #expect(vapor.kind != fluent.kind)
        #expect(vapor.capabilities.sorted.isEmpty)
    }

    @Test func capabilitySets() throws {
        let http = try Capability("generate.http-controller")
        let migration = try Capability("generate.migration")
        let set = CapabilitySet([http])
        #expect(set.contains(http) && !set.contains(migration))
        #expect(set.union(CapabilitySet([migration])).sorted == [http, migration])
        #expect(throws: MageError.self) { try Capability("Generate") }
        #expect(throws: MageError.self) { try Capability("a..b") }
    }

    @Test func architectureProfileIdIsTypedAndValidated() throws {
        #expect(CleanLayeredDDD().id.rawValue == "clean-layered-ddd")
        #expect(throws: MageError.self) { try ArchitectureProfileID("DDD") }
        let decoded = try JSONDecoder().decode([ArchitectureProfileID].self, from: Data("[\"clean-layered-ddd\"]".utf8))
        #expect(decoded == [CleanLayeredDDD().id])
    }

    @Test func cleanLayeredDDDDependencyDirection() {
        let profile = CleanLayeredDDD()
        #expect(profile.allowedDependencies(of: .domain).isEmpty)
        #expect(profile.isDependencyAllowed(from: .application, to: .domain))
        #expect(!profile.isDependencyAllowed(from: .domain, to: .application))
        #expect(!profile.isDependencyAllowed(from: .application, to: .interface))
        #expect(!profile.isDependencyAllowed(from: .application, to: .infrastructure))
        #expect(profile.isDependencyAllowed(from: .infrastructure, to: .application))
        #expect(!profile.isDependencyAllowed(from: .interface, to: .infrastructure))
        for layer in ArchitectureLayer.allCases where layer != .composition {
            #expect(profile.isDependencyAllowed(from: .composition, to: layer))
            #expect(!profile.isDependencyAllowed(from: layer, to: .composition))
        }
    }
}
