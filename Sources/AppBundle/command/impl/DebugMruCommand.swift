import AppKit
import Common

struct DebugMruCommand: Command {
    let args: DebugMruCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        io.out("=== MRU Debug Info ===")

        for workspace in Workspace.all.sortedBy(\.name) {
            io.out("")
            io.out("Workspace '\(workspace.name)':")

            let mruWindow = workspace.mostRecentWindowRecursive
            if let window = mruWindow {
                let title = try await window.title
                io.out("  mostRecentWindowRecursive: windowId=\(window.windowId), app=\(window.app.name ?? "nil"), title=\"\(title)\"")
            } else {
                io.out("  mostRecentWindowRecursive: (none)")
            }

            io.out("  MRU Stack (workspace level):")
            try await printMruStack(node: workspace, io: io, indent: "    ")
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
            io.out("=== Previous Focus (_prevFocus) ===")
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

    private func printMruStack(node: TreeNode, io: CmdIo, indent: String) async throws {
        let mruChildren = node.mruChildrenDebug
        if mruChildren.isEmpty {
            io.out("\(indent)(empty MRU stack)")
            return
        }

        for (index, child) in mruChildren.enumerated() {
            let prefix = index == 0 ? "[MRU]" : "[\(index)]"
            let description = try await describeNode(child)
            io.out("\(indent)\(prefix) \(description)")

            // Recursively print MRU stack for containers
            if !(child is Window) {
                try await printMruStack(node: child, io: io, indent: indent + "  ")
            }
        }
    }

    private func describeNode(_ node: TreeNode) async throws -> String {
        if let window = node as? Window {
            let title = try await window.title
            return "Window(id=\(window.windowId), app=\(window.app.name ?? "nil"), title=\"\(title)\", floating=\(window.isFloating))"
        } else if let container = node as? TilingContainer {
            return "TilingContainer(layout=\(container.layout), orientation=\(container.orientation), children=\(container.children.count))"
        } else if node is Workspace {
            return "Workspace"
        } else {
            return String(describing: type(of: node))
        }
    }
}
