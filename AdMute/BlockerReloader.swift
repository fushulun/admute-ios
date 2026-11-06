import Foundation
import SafariServices

/// 通知 Safari 重新加载规则，并读取扩展当前是否被用户启用。
enum BlockerReloader {
    static func reload(completion: @escaping (Result<Void, Error>) -> Void) {
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: BlockerShared.blockerBundleID) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    static func refreshState(completion: @escaping (Bool) -> Void) {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: BlockerShared.blockerBundleID) { state, _ in
            DispatchQueue.main.async {
                completion(state?.isEnabled ?? false)
            }
        }
    }
}
