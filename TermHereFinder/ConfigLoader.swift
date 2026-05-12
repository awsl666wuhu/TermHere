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

// MARK: - Entry types

struct OpenWithEntry: Codable {
    let title: String
    let bundleId: String
    let args: [String]?
    var showOnlyIfInstalled: Bool? = true
}

struct RunCommandEntry: Codable {
    let title: String
    let command: String
}

struct MoveToEntry: Codable {
    let title: String
    let destination: String
}

struct NewFileEntry: Codable {
    let title: String
    let `extension`: String
    let filename: String
    let content: String
}

// MARK: - Loader

enum ConfigLoader {
    /// Loads all `*.json` files from `directory`, decoding each as `T`.
    /// Missing directory → empty array. Malformed files → silently skipped.
    /// Results are sorted by `title` (case-insensitive ascending).
    static func loadAll<T: Codable & Titled>(from directory: URL) throws -> [T] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directory.path) else { return [] }

        let contents = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let jsons = contents.filter { $0.pathExtension == "json" }
        let decoder = JSONDecoder()

        var entries: [T] = []
        for url in jsons {
            guard let data = try? Data(contentsOf: url),
                  let entry = try? decoder.decode(T.self, from: data) else { continue }
            entries.append(entry)
        }
        return entries.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}

protocol Titled { var title: String { get } }
extension OpenWithEntry: Titled {}
extension RunCommandEntry: Titled {}
extension MoveToEntry: Titled {}
extension NewFileEntry: Titled {}
