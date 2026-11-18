import Foundation

public struct StandardOutput: OutputSink {
    public init() {}
    public func write(_ text: String) { FileHandle.standardOutput.write(Data(text.utf8)) }
}

public struct StandardError: OutputSink {
    public init() {}
    public func write(_ text: String) { FileHandle.standardError.write(Data(text.utf8)) }
}
