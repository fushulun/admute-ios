import Foundation
import Combine

@MainActor
final class RuleStore: ObservableObject {
    @Published private(set) var rules: [Rule] = []
    @Published private(set) var extensionEnabled = false
    @Published private(set) var message: String?

    init() {
        loadRules()
        compileAndWrite()
        refreshState()
    }

    // MARK: - 读取与保存

    private func loadRules() {
        let url = BlockerShared.rulesURL()
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Rule].self, from: data),
           !decoded.isEmpty {
            rules = decoded
        } else {
            rules = Rule.defaults
            persistRules()
        }
    }

    private func persistRules() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        try? data.write(to: BlockerShared.rulesURL(), options: .atomic)
    }

    // MARK: - 编译

    /// 只写文件，不通知 Safari。启动时用，避免每次打开 App 都弹错误。
    private func compileAndWrite() {
        guard let data = BlockerCompiler.buildJSON(from: rules) else {
            message = "规则编译失败，请检查域名格式"
            return
        }
        do {
            try data.write(to: BlockerShared.blockerListURL(), options: .atomic)
            message = nil
        } catch {
            message = "写入规则失败：\(error.localizedDescription)"
        }
    }

    /// 写入并让 Safari 立即重新加载。
    func applyChanges() {
        persistRules()
        compileAndWrite()

        BlockerReloader.reload { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.message = "已更新 \(BlockerCompiler.ruleCount(from: self.rules)) 条规则"
                self.refreshState()
            case .failure(let error):
                self.message = "Safari 未能加载规则：\(error.localizedDescription)。请先在 设置 › Safari › 扩展 中打开「静声规则」。"
            }
        }
    }

    func refreshState() {
        BlockerReloader.refreshState { [weak self] enabled in
            self?.extensionEnabled = enabled
        }
    }

    // MARK: - 编辑

    func add(pattern: String, kind: Rule.Kind, note: String) {
        let rule = Rule(pattern: pattern, kind: kind, note: note)
        rules.insert(rule, at: 0)
        applyChanges()
    }

    func setEnabled(_ rule: Rule, enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index].enabled = enabled
        applyChanges()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where rules.indices.contains(index) {
            rules.remove(at: index)
        }
        applyChanges()
    }

    func delete(_ rule: Rule) {
        rules.removeAll { $0.id == rule.id }
        applyChanges()
    }

    func resetToDefaults() {
        rules = Rule.defaults
        applyChanges()
    }
}
