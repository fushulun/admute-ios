import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = RuleStore()
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatusCard(store: store)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(store.rules) { rule in
                        RuleRow(rule: rule, store: store)
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets)
                    }
                } header: {
                    Text("规则 · \(store.rules.count)")
                } footer: {
                    Text("左滑删除。改动会立即写入并通知 Safari 重新加载。")
                }

                Section {
                    Button("重新载入到 Safari") {
                        store.applyChanges()
                    }
                    Button("恢复默认规则", role: .destructive) {
                        store.resetToDefaults()
                    }
                    if let message = store.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("仅拦截 Safari 内的网页广告，其他 App 内的广告不受影响。")
                }
            }
            .navigationTitle("静声")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddRuleView(store: store)
            }
            .onAppear {
                store.refreshState()
            }
        }
    }
}

struct StatusCard: View {
    @ObservedObject var store: RuleStore

    private var activeCount: Int {
        BlockerCompiler.ruleCount(from: store.rules)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text(store.extensionEnabled ? "已在 Safari 启用" : "尚未在 Safari 启用")
                        .font(.headline)
                    Text("\(activeCount) 条规则生效中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Circle()
                    .fill(store.extensionEnabled ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
            }

            Text("设置 › Safari › 扩展 › 静声规则，打开开关后即可拦截网页广告。")
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            } label: {
                Text("打开系统设置")
                    .font(.footnote.weight(.semibold))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

struct RuleRow: View {
    let rule: Rule
    let store: RuleStore

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.pattern)
                    .font(.system(.subheadline, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(rule.note.isEmpty ? rule.kind.title : "\(rule.kind.title) · \(rule.note)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { store.setEnabled(rule, enabled: $0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

struct AddRuleView: View {
    let store: RuleStore

    @Environment(\.dismiss) private var dismiss
    @State private var pattern = ""
    @State private var kind: Rule.Kind = .block
    @State private var note = ""

    private var normalized: String? {
        BlockerCompiler.normalizeDomain(pattern)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("域名") {
                    TextField("example.com", text: $pattern)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("支持 example.com、*.example.com、||example.com^ 三种写法。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("动作") {
                    Picker("动作", selection: $kind) {
                        ForEach(Rule.Kind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("备注") {
                    TextField("可选，例如「视频站贴片」", text: $note)
                }
            }
            .navigationTitle("新建规则")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.add(pattern: pattern, kind: kind, note: note)
                        dismiss()
                    }
                    .disabled(normalized == nil)
                }
            }
        }
    }
}

