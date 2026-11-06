import Foundation

struct Rule: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case block
        case allow

        var id: String { rawValue }

        var title: String {
            switch self {
            case .block: return "拦截"
            case .allow: return "放行"
            }
        }
    }

    var id: UUID
    var pattern: String
    var kind: Kind
    var enabled: Bool
    var note: String

    init(
        id: UUID = UUID(),
        pattern: String,
        kind: Kind = .block,
        enabled: Bool = true,
        note: String = ""
    ) {
        self.id = id
        self.pattern = pattern
        self.kind = kind
        self.enabled = enabled
        self.note = note
    }
}

extension Rule {
    /// 首次启动写入的默认规则。用户可以在列表里逐条关掉。
    static let defaults: [Rule] = [
        Rule(pattern: "doubleclick.net", note: "Google 广告"),
        Rule(pattern: "googlesyndication.com", note: "Google 广告"),
        Rule(pattern: "googleadservices.com", note: "Google 广告"),
        Rule(pattern: "adservice.google.com", note: "Google 广告"),
        Rule(pattern: "amazon-adsystem.com", note: "亚马逊广告"),
        Rule(pattern: "app.adjust.com", note: "归因追踪"),
        Rule(pattern: "appsflyer.com", note: "归因追踪"),
        Rule(pattern: "umeng.com", note: "统计"),
        Rule(pattern: "cpro.baidu.com", note: "百度联盟"),
        Rule(pattern: "pos.baidu.com", note: "百度统计"),
        Rule(pattern: "tanx.com", note: "阿里广告"),
        Rule(pattern: "adsrvr.org", note: "The Trade Desk"),
        Rule(pattern: "criteo.com", note: "Criteo"),
        Rule(pattern: "taboola.com", note: "内容推荐广告"),
        Rule(pattern: "outbrain.com", note: "内容推荐广告")
    ]
}
