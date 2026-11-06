import os

enum Log {
    private static let subsystem = "dev.kekayan.runs"
    static let app = Logger(subsystem: subsystem, category: "app")
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let api = Logger(subsystem: subsystem, category: "api")
    static let keychain = Logger(subsystem: subsystem, category: "keychain")
}
