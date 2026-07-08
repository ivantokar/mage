import Foundation

enum ValidationType: String, Codable {
    case email
    case phone
    case url
    case uuid
    case date
    case creditCard
    case custom
}

struct Field {
    let name: String
    let type: String
    let optional: Bool
    let validationType: ValidationType?
    let minLength: Int?
    let maxLength: Int?
    let min: Double?
    let max: Double?
    let pattern: String?

    init(
        name: String,
        type: String,
        optional: Bool = false,
        validationType: ValidationType? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        min: Double? = nil,
        max: Double? = nil,
        pattern: String? = nil
    ) {
        self.name = name
        self.type = type
        self.optional = optional
        self.validationType = validationType
        self.minLength = minLength
        self.maxLength = maxLength
        self.min = min
        self.max = max
        self.pattern = pattern
    }

    var swiftType: String {
        switch type.lowercased() {
        case "string", "text", "str":
            return "String"
        case "int", "integer":
            return "Int"
        case "double", "float", "decimal", "number":
            return "Double"
        case "bool", "boolean":
            return "Bool"
        case "date", "datetime", "timestamp":
            return "Date"
        case "uuid":
            return "UUID"
        case "data":
            return "Data"
        default:
            if type.hasSuffix("?") {
                return String(type.dropLast())
            }
            return type
        }
    }

    private static func normalizeType(_ rawType: String) -> String {
        let lower = rawType.lowercased()
        switch lower {
        case "bool", "boll", "boolen", "boolean":
            return "Bool"
        case "str", "string", "text":
            return "String"
        case "int", "integer":
            return "Int"
        case "double", "float", "decimal", "number", "num":
            return "Double"
        case "date", "datetime", "timestamp":
            return "Date"
        case "uuid":
            return "UUID"
        default:
            return rawType
        }
    }

    static func parseFields(_ fieldsString: String?) -> [Field] {
        guard let fieldsString = fieldsString, !fieldsString.isEmpty else {
            return []
        }

        return splitTopLevel(fieldsString, separator: ",")
            .compactMap { fieldStr in
                guard let separatorIndex = fieldStr.firstIndex(of: ":") else { return nil }

                let name = String(fieldStr[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
                let typeStart = fieldStr.index(after: separatorIndex)
                let typeStr = String(fieldStr[typeStart...]).trimmingCharacters(in: .whitespaces)

                guard !name.isEmpty, !typeStr.isEmpty else { return nil }

                let optional = typeStr.hasSuffix("?")
                let rawType = optional ? String(typeStr.dropLast()) : typeStr

                var validationType: ValidationType? = nil
                var minLength: Int? = nil
                var maxLength: Int? = nil
                var min: Double? = nil
                var max: Double? = nil
                var pattern: String? = nil
                var finalType = rawType

                let validationTypes = ["email", "phone", "url", "uuid", "date", "creditCard"]
                if validationTypes.contains(rawType) {
                    validationType = ValidationType(rawValue: rawType)
                    finalType = rawType == "uuid" ? "UUID" : "String"
                } else if rawType.starts(with: "number[") && rawType.contains("]") {
                    if let range = parseNumberRange(rawType) {
                        finalType = "Double"
                        min = range.min
                        max = range.max
                    }
                } else if rawType.starts(with: "string{") && rawType.contains("}") {
                    if let length = parseStringLength(rawType) {
                        finalType = "String"
                        minLength = length.min
                        maxLength = length.max
                    }
                } else if rawType.starts(with: "string(") && rawType.contains(")") {
                    if let pat = parsePattern(rawType) {
                        finalType = "String"
                        pattern = pat
                        validationType = .custom
                    }
                }

                let normalizedType = normalizeType(finalType)

                return Field(
                    name: name,
                    type: normalizedType,
                    optional: optional,
                    validationType: validationType,
                    minLength: minLength,
                    maxLength: maxLength,
                    min: min,
                    max: max,
                    pattern: pattern
                )
            }
    }

    private static func splitTopLevel(_ input: String, separator: Character) -> [String] {
        var results: [String] = []
        var current = ""
        var parenDepth = 0
        var bracketDepth = 0
        var braceDepth = 0

        for char in input {
            switch char {
            case "(": parenDepth += 1
            case ")": parenDepth = Swift.max(0, parenDepth - 1)
            case "[": bracketDepth += 1
            case "]": bracketDepth = Swift.max(0, bracketDepth - 1)
            case "{": braceDepth += 1
            case "}": braceDepth = Swift.max(0, braceDepth - 1)
            default: break
            }

            if char == separator && parenDepth == 0 && bracketDepth == 0 && braceDepth == 0 {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { results.append(trimmed) }
                current.removeAll(keepingCapacity: true)
            } else {
                current.append(char)
            }
        }

        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { results.append(trimmed) }
        return results
    }

    private static func parseNumberRange(_ str: String) -> (min: Double, max: Double)? {
        let pattern = #"(?:number|Double|Int)\[(\d+(?:\.\d+)?)-(\d+(?:\.\d+)?)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)),
              match.numberOfRanges == 3,
              let minRange = Range(match.range(at: 1), in: str),
              let maxRange = Range(match.range(at: 2), in: str),
              let minValue = Double(String(str[minRange])),
              let maxValue = Double(String(str[maxRange])) else { return nil }
        return (min: minValue, max: maxValue)
    }

    private static func parseStringLength(_ str: String) -> (min: Int, max: Int)? {
        let pattern = #"string\{(\d+),(\d+)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)),
              match.numberOfRanges == 3,
              let minRange = Range(match.range(at: 1), in: str),
              let maxRange = Range(match.range(at: 2), in: str),
              let minValue = Int(String(str[minRange])),
              let maxValue = Int(String(str[maxRange])) else { return nil }
        return (min: minValue, max: maxValue)
    }

    private static func parsePattern(_ str: String) -> String? {
        let pattern = #"string\(/(.*?)/\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)),
              match.numberOfRanges == 2,
              let patternRange = Range(match.range(at: 1), in: str) else { return nil }
        return String(str[patternRange])
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "type": type,
            "swiftType": swiftType,
            "optional": optional,
        ]

        if let validationType = validationType {
            dict["validationType"] = validationType.rawValue
        }
        if let minLength = minLength { dict["minLength"] = minLength }
        if let maxLength = maxLength { dict["maxLength"] = maxLength }
        if let min = min { dict["min"] = min }
        if let max = max { dict["max"] = max }
        if let pattern = pattern { dict["pattern"] = pattern }

        dict["hasValidation"] = validationType != nil || minLength != nil || maxLength != nil || min != nil || max != nil || pattern != nil
        dict["isEmail"] = validationType == .email
        dict["isPhone"] = validationType == .phone
        dict["isUrl"] = validationType == .url
        dict["isUuid"] = validationType == .uuid
        dict["isDate"] = validationType == .date
        dict["isCreditCard"] = validationType == .creditCard
        dict["hasPattern"] = pattern != nil
        dict["hasRange"] = min != nil || max != nil
        dict["hasLength"] = minLength != nil || maxLength != nil

        return dict
    }
}
