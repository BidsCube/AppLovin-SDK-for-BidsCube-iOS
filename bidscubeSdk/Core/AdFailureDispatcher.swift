import Foundation

/// Centralized delivery of ad failures to `AdCallback` on the main thread.
enum AdFailureDispatcher {
    static func deliver(
        placementId: String,
        format: String,
        callback: AdCallback?,
        error: Error
    ) {
        let code = AdErrorCode.from(error)
        let message = AdErrorCode.message(for: error)
        Logger.error(
            "Ad request failed (\(format)) placement=\(placementId) code=\(code) (\(AdErrorCode.describe(code))): \(message)",
            prefix: Constants.LogPrefixes.error
        )
        runOnMain {
            invokeAdFailed(callback, placementId: placementId, errorCode: code, errorMessage: message)
        }
    }

    static func deliver(
        placementId: String,
        format: String,
        callback: AdCallback?,
        errorCode: Int,
        errorMessage: String
    ) {
        deliver(
            placementId: placementId,
            format: format,
            callback: callback,
            error: BidscubeRequestError(errorCode: errorCode, message: errorMessage)
        )
    }

    private static func invokeAdFailed(
        _ callback: AdCallback?,
        placementId: String,
        errorCode: Int,
        errorMessage: String
    ) {
        guard let callback else { return }
        callback.onAdFailed(placementId, errorCode: errorCode, errorMessage: errorMessage)
    }

    private static func runOnMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}
