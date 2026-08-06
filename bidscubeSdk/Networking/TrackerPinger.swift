import Foundation

enum TrackerPinger {
    static func pingUrls(
        _ label: String,
        _ urls: [String],
        context: VastTrackingContext = VastTrackingContext(),
        errorCode: Int? = nil
    ) {
        for urlString in urls {
            let expanded = VastTrackingMacroReplacer.replace(
                urlString.trimmingCharacters(in: .whitespacesAndNewlines),
                context: context,
                errorCode: errorCode
            )
            guard let url = URL(string: expanded) else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            URLSession.shared.dataTask(with: request).resume()
            Logger.network("Tracking ping [\(label)]: \(url.absoluteString)")
        }
    }
}
