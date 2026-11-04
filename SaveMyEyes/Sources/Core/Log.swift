import Foundation
import os

/// Tagged log lines: unified logging (Console.app, subsystem `com.ammadeo.savemyeyes`) and,
/// in debug builds, stderr so `make run` output and Xcode's console show them too.
enum Log {
    private static let logger = Logger(subsystem: "com.ammadeo.savemyeyes", category: "app")

    static func info(_ tag: String, _ message: String) {
        logger.info("[\(tag, privacy: .public)] \(message, privacy: .public)")
        debugPrint(tag, message)
    }

    static func warn(_ tag: String, _ message: String) {
        logger.warning("[\(tag, privacy: .public)] \(message, privacy: .public)")
        debugPrint(tag, message)
    }

    static func error(_ tag: String, _ message: String) {
        logger.error("[\(tag, privacy: .public)] \(message, privacy: .public)")
        debugPrint(tag, message)
    }

    private static func debugPrint(_ tag: String, _ message: String) {
        #if DEBUG
        FileHandle.standardError.write(Data("[\(tag)] \(message)\n".utf8))
        #endif
    }
}
