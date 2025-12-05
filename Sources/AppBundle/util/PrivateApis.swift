import Cocoa

// Private APIs are APIs that we can build the app against, but they are not supported or documented by Apple
// We can see their names as symbols in the SDK (see https://github.com/lwouis/MacOSX-SDKs)
// However their full signature is a best-effort of retro-engineering
// Very little information is available about private APIs. I tried to document them as much as possible here
// Some links:
// * Webkit repo: https://github.com/WebKit/webkit/blob/master/Source/WebCore/PAL/pal/spi/cg/CoreGraphicsSPI.h
// * Alt-tab-macos issue: https://github.com/lwouis/alt-tab-macos/pull/87#issuecomment-558624755
// * Github repo with retro-engineered internals: https://github.com/NUIKit/CGSInternal

typealias CGSConnectionID = UInt32
typealias CGSSpaceID = UInt64
typealias ScreenUuid = CFString

let cgsMainConnectionId = CGSMainConnectionID()

struct CGSWindowCaptureOptions: OptionSet {
    let rawValue: UInt32
    static let ignoreGlobalClipShape = CGSWindowCaptureOptions(rawValue: 1 << 11)
    // on a retina display, 1px is spread on 4px, so nominalResolution is 1/4 of bestResolution
    static let nominalResolution = CGSWindowCaptureOptions(rawValue: 1 << 9)
    static let bestResolution = CGSWindowCaptureOptions(rawValue: 1 << 8)
}

enum SLPSMode: UInt32 {
    case allWindows = 0x100
    case userGenerated = 0x200
    case noWindows = 0x400
}

// returns the connection to the WindowServer. This connection ID is required when calling other APIs
// * macOS 10.10+
@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

// returns an array of CGImage of the windows which ID is given as `windowList`. `windowList` is supposed to be an array of IDs but in my test on High Sierra, the function ignores other IDs than the first, and always returns the screenshot of the first window in the array
// * performance: the `HW` in the name seems to imply better performance, and it was observed by some contributors that it seems to be faster (see https://github.com/lwouis/alt-tab-macos/issues/45) than other methods
// * quality: medium
// * minimized windows: yes
// * windows in other spaces: yes
// * offscreen content: no
// * macOS 10.10+
@_silgen_name("CGSHWCaptureWindowList")
func CGSHWCaptureWindowList(_ cid: CGSConnectionID, _ windowList: inout CGWindowID, _ windowCount: UInt32, _ options: CGSWindowCaptureOptions) -> Unmanaged<CFArray>

// returns the connection ID for the provided window
// * macOS 10.10+
@_silgen_name("CGSGetWindowOwner") @discardableResult
func CGSGetWindowOwner(_ cid: CGSConnectionID, _ wid: CGWindowID, _ windowCid: inout CGSConnectionID) -> CGError

// returns the PSN for the provided connection ID
// * macOS 10.10+
@_silgen_name("CGSGetConnectionPSN") @discardableResult
func CGSGetConnectionPSN(_ cid: CGSConnectionID, _ psn: inout ProcessSerialNumber) -> CGError

// returns an array of displays (as NSDictionary) -> each having an array of spaces (as NSDictionary) at the "Spaces" key; each having a space ID (as UInt64) at the "id64" key
// * macOS 10.10+
// /!\ only returns correct values if the user has checked the checkbox in Preferences > Mission Control > "Displays have separate Spaces"
@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray

struct CGSCopyWindowsOptions: OptionSet {
    let rawValue: Int
    static let invisible1 = CGSCopyWindowsOptions(rawValue: 1 << 0)
    // retrieves windows when their app is assigned to All Spaces, and windows at ScreenSaver level 1000
    static let screenSaverLevel1000 = CGSCopyWindowsOptions(rawValue: 1 << 1)
    static let invisible2 = CGSCopyWindowsOptions(rawValue: 1 << 2)
    static let unknown1 = CGSCopyWindowsOptions(rawValue: 1 << 3)
    static let unknown2 = CGSCopyWindowsOptions(rawValue: 1 << 4)
    static let desktopIconWindowLevel2147483603 = CGSCopyWindowsOptions(rawValue: 1 << 5)
}

struct CGSCopyWindowsTags: OptionSet {
    let rawValue: Int
    static let level0 = CGSCopyWindowsTags(rawValue: 1 << 0)
    static let noTitleMaybePopups = CGSCopyWindowsTags(rawValue: 1 << 1)
    static let unknown1 = CGSCopyWindowsTags(rawValue: 1 << 2)
    static let mainMenuWindowAndDesktopIconWindow = CGSCopyWindowsTags(rawValue: 1 << 3)
    static let unknown2 = CGSCopyWindowsTags(rawValue: 1 << 4)
}

// returns an array of window IDs (as UInt32) for the space(s) provided as `spaces`
// the elements of the array are ordered by the z-index order of the windows in each space, with some exceptions where spaces mix
// * macOS 10.10+
@_silgen_name("CGSCopyWindowsWithOptionsAndTags")
func CGSCopyWindowsWithOptionsAndTags(_ cid: CGSConnectionID, _ owner: Int, _ spaces: CFArray, _ options: Int, _ setTags: inout Int, _ clearTags: inout Int) -> CFArray

// returns the current space ID on the provided display UUID
// * macOS 10.10+
@_silgen_name("CGSManagedDisplayGetCurrentSpace")
func CGSManagedDisplayGetCurrentSpace(_ cid: CGSConnectionID, _ displayUuid: ScreenUuid) -> CGSSpaceID

// adds the provided windows to the provided spaces
// * macOS 10.10-12.2
@_silgen_name("CGSAddWindowsToSpaces")
func CGSAddWindowsToSpaces(_ cid: CGSConnectionID, _ windows: NSArray, _ spaces: NSArray) -> Void

// remove the provided windows from the provided spaces
// * macOS 10.10-12.2
@_silgen_name("CGSRemoveWindowsFromSpaces")
func CGSRemoveWindowsFromSpaces(_ cid: CGSConnectionID, _ windows: NSArray, _ spaces: NSArray) -> Void

// Move the given windows (CGWindowIDs) to the given space (CGSSpaceID)
// doesn't move fullscreen'ed windows
// * macOS 10.10+
@_silgen_name("CGSMoveWindowsToManagedSpace")
func CGSMoveWindowsToManagedSpace(_ cid: CGSConnectionID, _ windows: NSArray, _ space: CGSSpaceID) -> Void

// focuses the front process
// * macOS 10.12+
@_silgen_name("_SLPSSetFrontProcessWithOptions") @discardableResult
func _SLPSSetFrontProcessWithOptions(_ psn: inout ProcessSerialNumber, _ wid: CGWindowID, _ mode: SLPSMode.RawValue) -> CGError

// sends bytes to the WindowServer
// more context: https://github.com/Hammerspoon/hammerspoon/issues/370#issuecomment-545545468
// * macOS 10.12+
@_silgen_name("SLPSPostEventRecordTo") @discardableResult
func SLPSPostEventRecordTo(_ psn: inout ProcessSerialNumber, _ bytes: inout UInt8) -> CGError

// Note: _AXUIElementGetWindow is declared in PrivateApi/include/private.h
// and imported via the PrivateApi module

// returns the provided CGWindow property for the provided CGWindowID
// * macOS 10.10+
@_silgen_name("CGSCopyWindowProperty") @discardableResult
func CGSCopyWindowProperty(_ cid: CGSConnectionID, _ wid: CGWindowID, _ property: CFString, _ value: inout CFTypeRef?) -> CGError

enum CGSSpaceMask: Int {
    case current = 5
    case other = 6
    case all = 7
}

// get the CGSSpaceIDs for the given windows (CGWindowIDs)
// * macOS 10.10+
@_silgen_name("CGSCopySpacesForWindows")
func CGSCopySpacesForWindows(_ cid: CGSConnectionID, _ mask: CGSSpaceMask.RawValue, _ wids: CFArray) -> CFArray

// returns window level (see definition in CGWindowLevel.h) of provided window
// * macOS 10.10+
@_silgen_name("CGSGetWindowLevel") @discardableResult
func CGSGetWindowLevel(_ cid: CGSConnectionID, _ wid: CGWindowID, _ level: inout CGWindowLevel) -> CGError

// returns status of the checkbox in System Preferences > Security & Privacy > Privacy > Screen Recording
// returns 1 if checked or 0 if unchecked; also prompts the user the first time if unchecked
// the return value will be the same during the app lifetime; it will not reflect the actual status of the checkbox
@_silgen_name("SLSRequestScreenCaptureAccess") @discardableResult
func SLSRequestScreenCaptureAccess() -> UInt8

// for some reason, these attributes are missing from AXAttributeConstants
let kAXFullscreenAttribute = "AXFullScreen"
let kAXStatusLabelAttribute = "AXStatusLabel"

// for some reason, these attributes are missing from AXRoleConstants
let kAXDocumentWindowSubrole = "AXDocumentWindow"

enum CGSSymbolicHotKey: Int, CaseIterable {
    case commandTab = 1
    case commandShiftTab = 2
    case commandKeyAboveTab = 6 // see keyAboveTabDependingOnInputSource
}

// enables/disables a symbolic hotkeys. These are system shortcuts such as command+tab or Spotlight
// it is possible to find all the existing hotkey IDs by using CGSGetSymbolicHotKeyValue on the first few hundred numbers
// note: the effect of enabling/disabling persists after the app is quit
@_silgen_name("CGSSetSymbolicHotKeyEnabled") @discardableResult
func CGSSetSymbolicHotKeyEnabled(_ hotKey: CGSSymbolicHotKey.RawValue, _ isEnabled: Bool) -> CGError

func setNativeCommandTabEnabled(_ isEnabled: Bool, _ hotkeys: [CGSSymbolicHotKey] = CGSSymbolicHotKey.allCases) {
    for hotkey in hotkeys {
        CGSSetSymbolicHotKeyEnabled(hotkey.rawValue, isEnabled)
    }
}

// returns info about a given psn
// * macOS 10.9-10.15 (officially removed in 10.9, but available as a private API still)
@_silgen_name("GetProcessInformation") @discardableResult
func GetProcessInformation(_ psn: inout ProcessSerialNumber, _ info: inout ProcessInfoRec) -> OSErr

// returns the psn for a given pid
// * macOS 10.9-10.15 (officially removed in 10.9, but available as a private API still)
@_silgen_name("GetProcessForPID") @discardableResult
func GetProcessForPID(_ pid: pid_t, _ psn: inout ProcessSerialNumber) -> OSStatus

enum CGSSpaceType: Int {
    case user = 0
    case system = 2
    case fullscreen = 4
}

// get the CGSSpaceType for a given space. Maybe useful for fullscreen windows
// * macOS 10.10+
@_silgen_name("CGSSpaceGetType")
func CGSSpaceGetType(_ cid: CGSConnectionID, _ sid: CGSSpaceID) -> CGSSpaceType

// move a window to a Space; works with fullscreen windows
// with fullscreen window, sending it back to its original state later seems to mess with macOS internals. The Space appears fully black
// this API seems unreliable to use
// the last param seem to work with 0x80007; not sure what it means
// * macOS 10.10-12.2
@_silgen_name("CGSSpaceAddWindowsAndRemoveFromSpaces")
func CGSSpaceAddWindowsAndRemoveFromSpaces(_ cid: CGSConnectionID, _ sid: CGSSpaceID, _ wid: NSArray, _ notSure: Int) -> Void

// get the display UUID with the active menubar (other menubar are dimmed)
@_silgen_name("CGSCopyActiveMenuBarDisplayIdentifier")
func CGSCopyActiveMenuBarDisplayIdentifier(_ cid: CGSConnectionID) -> ScreenUuid

// MARK: - Window Focus Helpers

/// Convert a window ID to its owning process's PSN
func windowIdToPsn(_ wid: CGWindowID) -> ProcessSerialNumber? {
    var elementConnection = CGSConnectionID(0)
    guard CGSGetWindowOwner(cgsMainConnectionId, wid, &elementConnection) == .success else {
        return nil
    }
    var psn = ProcessSerialNumber()
    guard CGSGetConnectionPSN(elementConnection, &psn) == .success else {
        return nil
    }
    return psn
}

/// Make a window the key window by sending a synthetic event to the WindowServer
/// Based on: https://github.com/Hammerspoon/hammerspoon/issues/370#issuecomment-545545468
func makeKeyWindow(_ psn: inout ProcessSerialNumber, _ wid: CGWindowID) {
    var bytes = [UInt8](repeating: 0, count: 0xf8)
    bytes[0x04] = 0xf8
    bytes[0x08] = 0x0d
    bytes[0x8a] = 0x01  // 0x01 = activate window

    var widCopy = wid
    _ = withUnsafeMutablePointer(to: &widCopy) { widPtr in
        memcpy(&bytes[0x3c], widPtr, MemoryLayout<UInt32>.size)
    }
    SLPSPostEventRecordTo(&psn, &bytes[0])
}

/// Make a window the key window using two-message approach (DOWN + UP events)
/// This simulates a complete click-to-focus cycle and is more robust for some apps
/// Based on: alt-tab-macos implementation
func makeKeyWindowTwoPhase(_ psn: inout ProcessSerialNumber, _ wid: CGWindowID) {
    var widCopy = wid

    // Message 1: Focus DOWN - begin focus transition
    var bytes1 = [UInt8](repeating: 0, count: 0xf8)
    bytes1[0x04] = 0xF8
    bytes1[0x08] = 0x01  // DOWN event
    bytes1[0x3a] = 0x10
    memcpy(&bytes1[0x3c], &widCopy, MemoryLayout<UInt32>.size)
    memset(&bytes1[0x20], 0xFF, 0x10)  // Activation mask

    // Message 2: Focus UP - complete focus transition
    var bytes2 = [UInt8](repeating: 0, count: 0xf8)
    bytes2[0x04] = 0xF8
    bytes2[0x08] = 0x02  // UP event
    bytes2[0x3a] = 0x10
    memcpy(&bytes2[0x3c], &widCopy, MemoryLayout<UInt32>.size)
    memset(&bytes2[0x20], 0xFF, 0x10)  // Activation mask

    // Send both messages to complete the focus cycle
    SLPSPostEventRecordTo(&psn, &bytes1[0])
    SLPSPostEventRecordTo(&psn, &bytes2[0])
}

/// Deactivate a window by sending a synthetic event to the WindowServer
func deactivateWindow(_ psn: inout ProcessSerialNumber, _ wid: CGWindowID) {
    var bytes = [UInt8](repeating: 0, count: 0xf8)
    bytes[0x04] = 0xf8
    bytes[0x08] = 0x0d
    bytes[0x8a] = 0x02  // 0x02 = deactivate window

    var widCopy = wid
    _ = withUnsafeMutablePointer(to: &widCopy) { widPtr in
        memcpy(&bytes[0x3c], widPtr, MemoryLayout<UInt32>.size)
    }
    SLPSPostEventRecordTo(&psn, &bytes[0])
}

/// Defer window raise by sending a synthetic event to the WindowServer
func deferWindowRaise(_ psn: inout ProcessSerialNumber, _ wid: CGWindowID) {
    var bytes = [UInt8](repeating: 0, count: 0xf8)
    bytes[0x04] = 0xf8
    bytes[0x08] = 0x0d
    bytes[0x8a] = 0x09  // 0x09 = defer raise

    var widCopy = wid
    _ = withUnsafeMutablePointer(to: &widCopy) { widPtr in
        memcpy(&bytes[0x3c], widPtr, MemoryLayout<UInt32>.size)
    }
    SLPSPostEventRecordTo(&psn, &bytes[0])
}
