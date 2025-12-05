public struct DebugMruCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .debugMru,
        allowInConfig: false,
        help: debug_mru_help_generated,
        flags: [:],
        posArgs: [],
    )
}
