# 静声 AdMute · iOS 工程（Safari 内容拦截版）

一个可编译的 iOS 工程：宿主 App 管理规则，Safari 扩展执行拦截。
不需要 DNS 权限、不需要付费开发者账号即可在 Xcode 里装到自己的 iPhone。

---

## 先说清楚：为什么这里没有现成的 .ipa

`.ipa` 必须在 macOS 上用 Xcode 编译并签名，Linux 环境没有 iOS SDK，也没有 `codesign`。
本工程提供三种拿到 IPA 的方式，按你手上的设备选。

| 方式 | 需要什么 | 产物 | 有效期 |
|---|---|---|---|
| A. Xcode 直接运行 | Mac + Xcode + 任意 Apple ID | 直接装到设备，无 IPA 文件 | 免费账号 7 天，需重装 |
| B. GitHub Actions | 一个 GitHub 账号（无需 Mac） | 未签名 `.ipa`，再用 Sideloadly/AltStore 自签 | 取决于签名工具，7 天 |
| C. 付费开发者账号 | Mac + 99 美元/年账号 | 已签名 `.ipa` / TestFlight | 1 年 |

> 免费账号无法使用「网络扩展（DNS 代理）」，这也是这次选 Safari 内容拦截版的原因：
> 它只需要一个普通 App Extension，免费证书就能跑。

---

## 目录结构

```
project.yml                     XcodeGen 工程描述
AdMute/                         宿主 App（SwiftUI）
  AdMuteApp.swift
  ContentView.swift             首页、规则列表、新建规则
  RuleStore.swift               规则读写、编译、通知 Safari 重载
  BlockerReloader.swift         SFContentBlockerManager 封装
  Info.plist / AdMute.entitlements
AdMuteBlocker/                  Safari 内容拦截扩展
  BlockerRequestHandler.swift   把规则 JSON 交给系统
  blockerList.json              内置兜底规则（App 未写入时使用）
  Info.plist / AdMuteBlocker.entitlements
Shared/                         两个 target 共用
  BlockerShared.swift           共享容器与标识
  Rule.swift                    数据模型与默认规则
  BlockerCompiler.swift         规则 → Safari JSON 编译
scripts/
  build-unsigned-ipa.sh
  build-signed-ipa.sh
.github/workflows/build-ipa.yml
```

---

## 方式 A：Xcode 直接运行（推荐，最省事）

```bash
brew install xcodegen
cd 静声AdMute-iOS工程
xcodegen generate
open AdMute.xcodeproj
```

1. Xcode 里选中 **AdMute** target → Signing & Capabilities → Team 选你的 Apple ID。
2. 把两个 target 的 Bundle Identifier 改成你自己的（必须唯一）。
3. 手机连上，选真机，⌘R 运行。
4. 手机上：**设置 › Safari › 扩展 › 静声规则** → 打开开关 → 允许访问所有网站。
5. 回到 App，状态卡会变成「已在 Safari 启用」。

## 方式 B：GitHub Actions 出未签名 IPA（没有 Mac 也能做）

1. 把整个目录推到 GitHub 仓库（默认分支 `main`）。
2. Actions 里跑 `Build unsigned IPA`，结束后在 Artifacts 下载 `AdMute-unsigned-ipa.zip`，解压得到 `.ipa`。
3. Windows 上用 [Sideloadly](https://sideloadly.io/) 或 AltStore，登录你的 Apple ID 签名安装。

> 注意：自签工具通常会剥离 App Group 权限。此时扩展只读 `blockerList.json` 里的内置规则，
> App 内的规则编辑不会同步过去。要完整体验规则管理，请用方式 A 或 C。

## 方式 C：已签名 IPA

```bash
TEAM_ID=你的10位TeamID ./scripts/build-signed-ipa.sh
```

产物在 `dist/`。导出方式默认 `development`（装到已注册设备）；要上 TestFlight 把
`scripts/build-signed-ipa.sh` 里的 `method` 改成 `app-store`，再走 App Store Connect 上传。

---

## 需要改的三处 ID

三处必须完全一致，否则扩展读不到共享容器：

1. `project.yml` 里的 `PRODUCT_BUNDLE_IDENTIFIER`（两个 target）
2. `AdMute/AdMute.entitlements` 与 `AdMuteBlocker/AdMuteBlocker.entitlements` 里的 App Group
3. `Shared/BlockerShared.swift` 里的 `appGroupID` 与 `blockerBundleID`

例如统一改成：

```
com.yourname.admute
com.yourname.admute.blocker
group.com.yourname.admute
```

App Group 还需要在开发者后台的 Identifiers 里为两个 App ID 勾选 App Groups 并创建同名组。
**个人免费团队可能不支持 App Groups**——Xcode 报 entitlement 错误时，就是这条路走不通，
请改用付费账号（方式 C）。

---

## 规则怎么写

App 内支持四种写法，编译时会统一归一化成域名：

| 写法 | 示例 |
|---|---|
| 纯域名 | `doubleclick.net` |
| 通配 | `*.doubleclick.net` |
| Adblock | `||doubleclick.net^` |
| 例外（放行） | `@@||example.com^` |

编译规则：先写全部拦截规则，再写 `ignore-previous-rules` 放行规则——顺序反了白名单会失效。
单次最多 50,000 条（`BlockerCompiler.maxRules`），超出部分截断。

## 已知限制

- **只作用于 Safari**。微信、抖音、B 站 App 内的广告拦不到，这是内容拦截扩展的边界。
- **按域名拦截**，不是按元素。想隐藏页面里的某个 banner，需要写 `css-display-none` 的 selector 规则，本版本没做。
- **免费账号 7 天有效**，到期要重新运行一次。
- **改 Bundle ID 后必须重装**，旧 App 不会自动更新。
- 本项目未在真机编译验证过（本环境无 macOS），首次构建如遇报错多为 Bundle ID / App Group 配置问题。

## 下一步能加什么

- 订阅远程列表（拉取 EasyList，转成 Safari 规则）
- 规则命中统计（需要扩展侧上报，内容拦截扩展本身不执行代码，只能做粗粒度计数）
- CSS 隐藏规则编辑器
- iCloud 同步规则
