import Foundation

struct ScriptStore {
    private static let key = "com.camerateleprompter.scripts"

    static func save(_ scripts: [Script]) {
        guard let data = try? JSONEncoder().encode(scripts) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> [Script] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let scripts = try? JSONDecoder().decode([Script].self, from: data) else {
            return []
        }
        return scripts
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
