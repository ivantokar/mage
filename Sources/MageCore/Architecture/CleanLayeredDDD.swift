/// The Clean Layered DDD profile (see issue #18).
///
/// ```text
///                     Domain
///                       ▲
///                 Application
///                  ▲         ▲
///           Interface    Infrastructure
///                  \         /
///                Composition Root
/// ```
public struct CleanLayeredDDD: ArchitectureProfile {
    public init() {}

    public var id: ArchitectureProfileID {
        // The literal is valid; a failure here is a programming error caught by tests.
        try! ArchitectureProfileID("clean-layered-ddd")
    }

    public var layers: [ArchitectureLayer] { ArchitectureLayer.allCases }

    public func allowedDependencies(of layer: ArchitectureLayer) -> Set<ArchitectureLayer> {
        switch layer {
        case .domain: []
        case .application: [.domain]
        case .infrastructure: [.domain, .application]
        case .interface: [.application]
        case .composition: [.domain, .application, .infrastructure, .interface]
        }
    }
}
