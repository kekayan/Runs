import Foundation

struct AppSettings: Codable {
    var selectedRepositoryIDs: Set<Int>

    // UserDefaults key
    private static let userDefaultsKey = "dev.kekayan.runs.settings"

    init(selectedRepositoryIDs: Set<Int> = []) {
        self.selectedRepositoryIDs = selectedRepositoryIDs
    }

    // Load settings from UserDefaults
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    // Save settings to UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(self) else {
            print("Failed to encode settings")
            return
        }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }

    // Clear all settings
    static func clear() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
