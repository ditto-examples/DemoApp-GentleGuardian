import Foundation
import Observation
import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

/// `@Observable` cache mapping Ditto attachment tokens to decoded platform images.
///
/// Picker rows reference this loader to render thumbnails next to custom-item
/// names without re-fetching on every redraw. Misses kick off a background
/// fetch via `DittoManager` and publish the result back into the cache.
@Observable
@MainActor
final class CustomItemAttachmentLoader {

    /// Cache state per token.
    enum LoadState: Equatable {
        case notLoaded
        case loading
        case loaded(PlatformImage)
        case failed
    }

    /// Token-keyed state for SwiftUI consumption.
    private(set) var states: [String: LoadState] = [:]

    private let dittoManager: any DittoManaging
    private var inflight: Set<String> = []

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    /// Returns the loaded image for a token, if any. Triggers a background fetch
    /// on first miss; subsequent calls receive the cached state synchronously.
    func image(for token: String?) -> PlatformImage? {
        guard let token, !token.isEmpty else { return nil }
        switch states[token] {
        case .loaded(let image):
            return image
        case .loading, .failed:
            return nil
        case .notLoaded, .none:
            startLoad(token: token)
            return nil
        }
    }

    /// Force-refreshes the image for a token (e.g. after an attachment was replaced).
    func refresh(token: String) {
        states[token] = .notLoaded
        inflight.remove(token)
        startLoad(token: token)
    }

    /// Drops a token from the cache (e.g. on item delete).
    func evict(token: String) {
        states.removeValue(forKey: token)
        inflight.remove(token)
    }

    private func startLoad(token: String) {
        guard !inflight.contains(token) else { return }
        inflight.insert(token)
        states[token] = .loading
        Task { [weak self] in
            guard let self else { return }
            let data = await self.dittoManager.fetchAttachment(token: token)
            await MainActor.run {
                self.inflight.remove(token)
                if let data, let image = PlatformImage(data: data) {
                    self.states[token] = .loaded(image)
                } else {
                    self.states[token] = .failed
                }
            }
        }
    }
}

// MARK: - SwiftUI helper

extension Image {
    /// Initializes a SwiftUI `Image` from a `PlatformImage` in a cross-platform way.
    init(platformImage: PlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}
