import AppKit
import Common

struct DebugMruCommand: Command {
    let args: DebugMruCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        io.out("=== MRU Debug Info ===")
        io.out("")

        for workspace in Workspace.all.sortedBy(\.name) {
            let mruWindow = workspace.mostRecentWindowRecursive
            let windowInfo: String
            if let window = mruWindow {
                let title = try await window.title
                windowInfo = "windowId=\(window.windowId), app=\(window.app.name ?? "nil"), title=\"\(title)\""
            } else {
                windowInfo = "(none)"
            }
            io.out("Workspace '\(workspace.name)': MRU window = \(windowInfo)")
        }

        io.out("")
        io.out("=== Current Focus ===")
        let currentFocus = focus
        if let focusedWindow = currentFocus.windowOrNil {
            let title = try await focusedWindow.title
            io.out("Focused: windowId=\(focusedWindow.windowId), app=\(focusedWindow.app.name ?? "nil"), title=\"\(title)\"")
        } else {
            io.out("Focused: (no window)")
        }
        io.out("Workspace: \(currentFocus.workspace.name)")

        if let prevFocus = prevFocus {
            io.out("")
            io.out("=== Previous Focus ===")
            if let prevWindow = prevFocus.windowOrNil {
                let title = try await prevWindow.title
                io.out("Previous: windowId=\(prevWindow.windowId), app=\(prevWindow.app.name ?? "nil"), title=\"\(title)\"")
            } else {
                io.out("Previous: (no window)")
            }
            io.out("Workspace: \(prevFocus.workspace.name)")
        }

        return true
    }
}
