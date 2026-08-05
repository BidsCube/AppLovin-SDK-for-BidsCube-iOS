import Foundation

enum TrackerPinger {
    static func pingUrls(_ label: String, _ urls: [String]) {
        for urlString in urls {
            guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            URLSession.shared.dataTask(with: request).resume()
            Logger.network("Companion tracking ping [\(label)]: \(url.absoluteString)")
        }
    }
}
