import Foundation

/// 主 App 与 Safari 扩展共享的路径与标识。
/// 改动 Bundle ID 时，这里的三个常量必须与 project.yml、两个 entitlements 保持一致。
enum BlockerShared {
    static let appGroupID = "group.com.example.admute"
    static let blockerBundleID = "com.example.admute.blocker"

    static let rulesFileName = "rules.json"
    static let blockerListFileName = "blockerList.json"

    static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url
        }
        // App Group 不可用时退化为沙盒目录：仅用于调试，扩展读不到。
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func rulesURL() -> URL {
        containerURL.appendingPathComponent(rulesFileName)
    }

    static func blockerListURL() -> URL {
        containerURL.appendingPathComponent(blockerListFileName)
    }
}
