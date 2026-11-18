/// A value passed to a ``Renderer``.
public indirect enum RenderValue: Sendable, Equatable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case array([RenderValue])
    /// Keys have no inherent order. A renderer must not let dictionary iteration order
    /// influence its output; sort the keys when enumerating.
    case dictionary([String: RenderValue])
}

/// A request to turn a renderable model into source text.
public struct RenderRequest: Sendable, Equatable {
    public var template: String
    public var context: [String: RenderValue]

    public init(template: String, context: [String: RenderValue] = [:]) {
        self.template = template
        self.context = context
    }
}

/// The boundary between Mage's semantic generation model and a text rendering engine.
///
/// The pipeline is `semantic model → renderable representation → renderer`. Templates
/// receive facts that are already decided (names, types, flags); they never decide
/// architecture semantics such as "is this an Aggregate Root". Stencil or any other
/// engine is an implementation detail behind this protocol.
///
/// Rendering must be deterministic: the same request always produces byte-identical output.
public protocol Renderer: Sendable {
    func render(_ request: RenderRequest) throws -> String
}
