import AppKit

/// A caching wrapper around AXUIElement that caches permanent and semi-permanent attributes
/// to reduce the number of expensive XPC calls to target applications.
///
/// Cached attributes:
/// - Permanent (never change): subrole, identifier, role
/// - Semi-permanent (rarely change): close/minimize/fullscreen/zoom button presence
final class CachedAxElement: AxUiElementMock {
    let ax: AXUIElement

    // MARK: - Permanent cache (never changes for window lifetime)
    // Using Optional<Optional<T>> pattern:
    //   - nil = not yet cached
    //   - .some(nil) = cached, value is nil
    //   - .some(value) = cached with value
    private var _subrole: String?? = nil
    private var _identifier: String?? = nil
    private var _role: String?? = nil

    // MARK: - Semi-permanent cache (rarely changes, can be invalidated)
    private var _closeButton: (any AxUiElementMock)?? = nil
    private var _minimizeButton: (any AxUiElementMock)?? = nil
    private var _fullscreenButton: (any AxUiElementMock)?? = nil
    private var _zoomButton: (any AxUiElementMock)?? = nil

    init(_ ax: AXUIElement) {
        self.ax = ax
    }

    // MARK: - AxUiElementMock conformance

    func get<Attr: ReadableAttr>(_ attr: Attr) -> Attr.T? {
        switch attr.key {
        // Permanent attributes - cached forever
        case kAXSubroleAttribute:
            if case .some(let cached) = _subrole {
                return cached as? Attr.T
            }
            let value = ax.get(attr)
            _subrole = .some(value as? String)
            return value

        case kAXIdentifierAttribute:
            if case .some(let cached) = _identifier {
                return cached as? Attr.T
            }
            let value = ax.get(attr)
            _identifier = .some(value as? String)
            return value

        case kAXRoleAttribute:
            if case .some(let cached) = _role {
                return cached as? Attr.T
            }
            let value = ax.get(attr)
            _role = .some(value as? String)
            return value

        // Semi-permanent attributes - button presence
        case kAXCloseButtonAttribute:
            if case .some(let cached) = _closeButton {
                return cached as? Attr.T
            }
            let value = ax.get(attr)
            _closeButton = .some(value as? (any AxUiElementMock))
            return value

        case kAXMinimizeButtonAttribute:
            if case .some(let cached) = _minimizeButton {
                return cached as? Attr.T
            }
            let value = ax.get(attr)
            _minimizeButton = .some(value as? (any AxUiElementMock))
            return value

        case kAXFullScreenButtonAttribute:
            if case .some(let cached) = _fullscreenButton {
                return cached as? Attr.T
            }
            let value = ax.get(attr)
            _fullscreenButton = .some(value as? (any AxUiElementMock))
            return value

        case kAXZoomButtonAttribute:
            if case .some(let cached) = _zoomButton {
                return cached as? Attr.T
            }
            let value = ax.get(attr)
            _zoomButton = .some(value as? (any AxUiElementMock))
            return value

        default:
            // All other attributes are fetched directly without caching
            return ax.get(attr)
        }
    }

    func containingWindowId() -> CGWindowID? {
        ax.containingWindowId()
    }

    /// Returns the underlying AXUIElement.
    /// Overrides the default `cast` from AxUiElementMock extension.
    var cast: AXUIElement { ax }

    // MARK: - Cache invalidation

    /// Invalidate semi-permanent caches (call when window structure might have changed)
    func invalidateButtonCache() {
        _closeButton = nil
        _minimizeButton = nil
        _fullscreenButton = nil
        _zoomButton = nil
    }

    /// Invalidate all caches (rarely needed)
    func invalidateAllCaches() {
        _subrole = nil
        _identifier = nil
        _role = nil
        invalidateButtonCache()
    }
}
