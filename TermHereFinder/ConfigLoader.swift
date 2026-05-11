import Foundation

enum TemplateSubstitution {
    /// Replaces `{key}` tokens in `template` with `variables[key]`.
    /// Unknown tokens are left as-is.
    static func apply(_ template: String, variables: [String: String]) -> String {
        var result = template
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}
