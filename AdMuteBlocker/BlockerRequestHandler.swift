import Foundation
import SafariServices

/// Safari 内容拦截扩展的入口。
/// 系统会在需要时调用 beginRequest，我们只要把一份规则 JSON 交给它即可。
final class BlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let sharedURL = BlockerShared.blockerListURL()
        let bundledURL = Bundle.main.url(forResource: "blockerList", withExtension: "json")

        let source: URL?
        if FileManager.default.fileExists(atPath: sharedURL.path) {
            source = sharedURL
        } else {
            source = bundledURL
        }

        guard let url = source, let provider = NSItemProvider(contentsOf: url) else {
            context.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        context.completeRequest(returningItems: [provider], completionHandler: nil)
    }
}
