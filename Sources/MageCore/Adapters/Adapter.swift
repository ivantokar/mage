/// A validated lowercase identifier made of `a-z`, `0-9` and single `-` separators.
/// Used for adapter ids, architecture profile ids and capability ids.
struct Identifier {
    static func isValid(_ string: String, allowingDots: Bool = false) -> Bool {
        guard let first = string.first, first.isASCII, first.isLowercase else { return false }
        var previousWasSeparator = false
        for character in string {
            let isSeparator = character == "-" || (allowingDots && character == ".")
            let ok = (character.isASCII && (character.isLowercase || character.isNumber)) || isSeparator
            if !ok || (isSeparator && previousWasSeparator) { return false }
            previousWasSeparator = isSeparator
        }
        return !previousWasSeparator
    }
}

extension DiagnosticCode {
    public static let invalidIdentifier = DiagnosticCode("identifier.invalid")
}

private func invalidIdentifier(_ kind: String, _ string: String) -> MageError {
    MageError(
        code: .invalidIdentifier,
        message: "Invalid \(kind) '\(string)': use lowercase letters, digits and single '-' separators.")
}

/// The stable identifier of an adapter, for example `vapor` or `fluent`.
/// It is what the manifest stores and what `--framework` / `--persistence` accept.
public struct AdapterID: Sendable, Hashable, Comparable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) throws {
        guard Identifier.isValid(rawValue) else { throw invalidIdentifier("adapter id", rawValue) }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        do { try self.init(try decoder.singleValueContainer().decode(String.self)) } catch let error as MageError {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: error.description))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String { rawValue }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// The two independent adapter axes. Persistence is not implied by the framework:
/// Vapor does not mean Fluent.
public enum AdapterKind: String, Sendable, Codable, CaseIterable {
    case framework
    case persistence
}

/// A typed statement of something an adapter or profile can do, for example
/// `generate.http-controller`. A manifest value never implies support; only a declared
/// capability does.
public struct Capability: Sendable, Hashable, Comparable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) throws {
        guard Identifier.isValid(rawValue, allowingDots: true) else { throw invalidIdentifier("capability", rawValue) }
        self.rawValue = rawValue
    }

    public var description: String { rawValue }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct CapabilitySet: Sendable, Equatable {
    public private(set) var capabilities: Set<Capability>

    public init(_ capabilities: some Sequence<Capability> = []) {
        self.capabilities = Set(capabilities)
    }

    public func contains(_ capability: Capability) -> Bool { capabilities.contains(capability) }
    public func union(_ other: CapabilitySet) -> CapabilitySet { CapabilitySet(capabilities.union(other.capabilities)) }
    public var sorted: [Capability] { capabilities.sorted() }
}

/// Static description of an adapter. Concrete adapters (Vapor, Fluent, ...) live outside
/// Core and register descriptors; Core never imports them.
public struct AdapterDescriptor: Sendable, Equatable {
    public var id: AdapterID
    public var kind: AdapterKind
    public var displayName: String
    public var capabilities: CapabilitySet

    public init(id: AdapterID, kind: AdapterKind, displayName: String, capabilities: CapabilitySet = CapabilitySet()) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.capabilities = capabilities
    }
}
