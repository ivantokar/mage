/// The stable identifier of an architecture profile, for example `clean-layered-ddd`.
/// The architecture is a typed id, never a free-form string like `style: ddd`.
public struct ArchitectureProfileID: Sendable, Hashable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) throws {
        guard Identifier.isValid(rawValue) else {
            throw MageError(
                code: .invalidIdentifier,
                message: "Invalid architecture profile id '\(rawValue)': use lowercase letters, digits and single '-' separators.")
        }
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
}

/// The layers of Clean Layered DDD.
public enum ArchitectureLayer: String, Sendable, Codable, CaseIterable {
    case domain
    case application
    case infrastructure
    case interface
    case composition
}

/// Architecture behavior, independent of any framework.
///
/// This is the Phase 0 primitive: identity, layers and dependency direction. Folder
/// layout, component placement and validation rules are added by later phases.
public protocol ArchitectureProfile: Sendable {
    var id: ArchitectureProfileID { get }
    var layers: [ArchitectureLayer] { get }
    /// The layers that code in `layer` may depend on, besides itself.
    func allowedDependencies(of layer: ArchitectureLayer) -> Set<ArchitectureLayer>
}

extension ArchitectureProfile {
    public func isDependencyAllowed(from layer: ArchitectureLayer, to dependency: ArchitectureLayer) -> Bool {
        layer == dependency || allowedDependencies(of: layer).contains(dependency)
    }
}
