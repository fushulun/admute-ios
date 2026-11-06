import Foundation

/// 把用户规则编译成 Safari Content Blocker 能读的 JSON。
///
/// Safari 按数组顺序逐条判断，`ignore-previous-rules` 会撤销它之前已经命中的规则，
/// 所以必须先把所有拦截规则写进去，再写放行规则。
enum BlockerCompiler {
    /// Safari 对单个规则集有数量与内存限制，这里留出安全余量。
    static let maxRules = 50_000

    /// 接受 `example.com`、`*.example.com`、`||example.com^`、`@@||example.com^` 四种写法。
    static func normalizeDomain(_ raw: String) -> String? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !value.isEmpty else { return nil }

        if value.hasPrefix("@@") {
            value.removeFirst(2)
        }
        if value.hasPrefix("||") {
            value.removeFirst(2)
        }
        if value.hasSuffix("^") {
            value.removeLast()
        }
        while value.hasPrefix("*.") {
            value.removeFirst(2)
        }
        if value.hasPrefix(".") {
            value.removeFirst()
        }
        guard !value.isEmpty, value.count < 200 else { return nil }
        guard value.range(of: "^[a-z0-9.-]+$", options: .regularExpression) != nil else { return nil }
        guard value.contains(".") else { return nil }
        return value
    }

    static func buildJSON(from rules: [Rule]) -> Data? {
        let blocked = rules.filter { $0.enabled && $0.kind == .block }
        let allowed = rules.filter { $0.enabled && $0.kind == .allow }

        var items: [[String: Any]] = []

        for rule in blocked {
            guard let domain = normalizeDomain(rule.pattern) else { continue }
            items.append([
                "trigger": [
                    "url-filter": ".*",
                    "if-domain": ["*\(domain)"]
                ],
                "action": ["type": "block"]
            ])
            if items.count >= maxRules { break }
        }

        if items.count < maxRules {
            for rule in allowed {
                guard let domain = normalizeDomain(rule.pattern) else { continue }
                items.append([
                    "trigger": [
                        "url-filter": ".*",
                        "if-domain": ["*\(domain)"]
                    ],
                    "action": ["type": "ignore-previous-rules"]
                ])
                if items.count >= maxRules { break }
            }
        }

        return try? JSONSerialization.data(withJSONObject: items, options: [])
    }

    static func ruleCount(from rules: [Rule]) -> Int {
        rules.reduce(0) { partial, rule in
            guard rule.enabled, normalizeDomain(rule.pattern) != nil else { return partial }
            return partial + 1
        }
    }
}
