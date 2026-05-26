import Foundation
import MageStencilKit

extension String {
    func applying(caseStyle: NumenConfig.NamingConfig.CaseStyle) -> String {
        switch caseStyle {
        case .camelCase:    return camelCased()
        case .PascalCase:   return pascalCased()
        case .snake_case:   return snakeCased()
        case .kebabCase:    return kebabCased()
        }
    }
}
