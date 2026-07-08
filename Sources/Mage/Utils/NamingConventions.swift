import Foundation
import SwiftStencilKit

extension String {
    func applying(caseStyle: MageConfig.NamingConfig.CaseStyle) -> String {
        switch caseStyle {
        case .camelCase:    return camelCased()
        case .PascalCase:   return pascalCased()
        case .snake_case:   return snakeCased()
        case .kebabCase:    return kebabCased()
        }
    }
}
