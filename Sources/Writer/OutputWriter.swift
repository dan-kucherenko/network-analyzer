import Foundation

struct OutputWriter {
    static func write(content: String, to filePath: String) {
        if let data = (content + "\n").data(using: .utf8) {
            if FileManager.default.fileExists(atPath: filePath) {
                if let fileHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: filePath)) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
            }
        }
    }
}
