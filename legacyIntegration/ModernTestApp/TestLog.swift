import Foundation

enum TestLog {
    private static let queue = DispatchQueue(label: "com.bidscube.testapp.log")
    private(set) static var lines: [String] = []
    static var onUpdate: ((String) -> Void)?

    static func append(_ message: String) {
        let line = "[\(timestamp())] \(message)"
        queue.sync {
            lines.append(line)
            if lines.count > 200 {
                lines.removeFirst(lines.count - 200)
            }
        }
        DispatchQueue.main.async {
            onUpdate?(formattedText())
        }
        NSLog("%@", message)
    }

    static func clear() {
        queue.sync { lines.removeAll() }
        DispatchQueue.main.async {
            onUpdate?("")
        }
    }

    static func formattedText() -> String {
        queue.sync { lines.joined(separator: "\n") }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
