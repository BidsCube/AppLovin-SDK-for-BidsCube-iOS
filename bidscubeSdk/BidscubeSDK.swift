import Foundation
import UIKit
import StoreKit

public final class BidscubeSDK {
    private static var configuration: SDKConfig?
    private static var manualAdPosition: AdPosition?
    private static var responseAdPosition: AdPosition = .unknown
    private static var consentRequired: Bool = false
    private static var hasAdsConsentFlag: Bool = false
    private static var hasAnalyticsConsentFlag: Bool = false
    private static var consentDebugDeviceId: String?
    
    
    private static var activeBanners: [BannerAdView] = []

    
    public static func initialize(config: SDKConfig) {
        self.configuration = config
        Logger.configure(from: config)
        Logger.info("BidsCube SDK initialized with configuration")
        
        // Initialize SKAdNetwork if enabled
        if config.enableSKAdNetwork {
            initializeSKAdNetwork(config: config)
        }
    }
    
    
    public static func initialize() {
        let config = SDKConfig.Builder()
            .enableLogging(true)
            .enableDebugMode(false)
            .defaultAdTimeout(Constants.defaultTimeoutMs)
            .defaultAdPosition(Constants.defaultAdPosition)
            .baseURL(Constants.baseURL)
            .enableSKAdNetwork(true)
            .skAdNetworkId("skadnetwork.com.example")
            .skAdNetworkConversionValue(1)
            .build()
        
        initialize(config: config)
    }

    private static func createOnMainThread<T>(_ make: () -> T) -> T {
        if Thread.isMainThread {
            return make()
        } else {
            var result: T!
            DispatchQueue.main.sync {
                result = make()
            }
            return result
        }
    }

    public static func isInitialized() -> Bool {
        return configuration != nil
    }
    
    public static func getConfiguration() -> SDKConfig? {
        return configuration
    }

    public static func cleanup() {
        
        removeAllBanners()
        
        configuration = nil
        manualAdPosition = nil
        responseAdPosition = .unknown
        consentRequired = false
        hasAdsConsentFlag = false
        hasAnalyticsConsentFlag = false
        consentDebugDeviceId = nil
    }

    
    public static func setAdPosition(_ position: AdPosition) {
        manualAdPosition = position
    }

    public static func getCurrentAdPosition() -> AdPosition? {
        return manualAdPosition
    }

    public static func getResponseAdPosition() -> AdPosition {
        return responseAdPosition
    }
    
    public static func setResponseAdPosition(_ position: AdPosition) {
        responseAdPosition = position
    }

    public static func getEffectiveAdPosition() -> AdPosition {
        return manualAdPosition ?? responseAdPosition
    }

    public static func requestConsentInfoUpdate(callback: ConsentCallback) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            callback.onConsentInfoUpdated()
        }
    }

    public static func showConsentForm(_ callback: ConsentCallback) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            callback.onConsentFormShown()
            self.hasAdsConsentFlag = true
            self.hasAnalyticsConsentFlag = true
            callback.onConsentGranted()
            callback.onConsentStatusChanged(true)
        }
    }

    public static func enableConsentDebugMode(_ testDeviceId: String) {
        consentDebugDeviceId = testDeviceId
    }

    public static func resetConsent() {
        hasAdsConsentFlag = false
        hasAnalyticsConsentFlag = false
        consentRequired = false
    }

    public static func isConsentRequired() -> Bool {
        return consentRequired
    }

    public static func hasAdsConsent() -> Bool {
        return hasAdsConsentFlag
    }

    public static func hasAnalyticsConsent() -> Bool {
        return hasAnalyticsConsentFlag
    }

    public static func getConsentStatusSummary() -> String {
        return "required=\(consentRequired), ads=\(hasAdsConsentFlag), analytics=\(hasAnalyticsConsentFlag)"
    }

    
    public static func buildRequestURL(placementId: String, adType: AdType, ctaText: String? = nil) -> URL? {
        guard let config = configuration else {
            Logger.error("SDK not initialized")
            return nil
        }
        
        let timeout = config.defaultAdTimeoutMs
        let debug = config.enableDebugMode
        let position = getEffectiveAdPosition()
        
        return URLBuilder.buildAdRequestURL(
            base: config.baseURL,
            placementId: placementId,
            adType: adType,
            position: position,
            timeoutMs: timeout,
            debug: debug,
            ctaText: ctaText
        )
    }
    public static func showImageAd(_ placementId: String, _ callback: AdCallback?) {
        print("showImageAd called with placementId: \(placementId)")
        callback?.onAdLoading(placementId)
        
        // Build POST URL and request body
        let includeSKAdNetworks = configuration?.enableSKAdNetwork ?? false
        
        guard let url = URLBuilder.buildAdRequestURL(placementId: placementId, adType: .image, position: getEffectiveAdPosition(), timeoutMs: configuration?.defaultAdTimeoutMs ?? Constants.defaultTimeoutMs, debug: configuration?.enableDebugMode ?? false, includeSKAdNetworks: includeSKAdNetworks) else {
            print("Failed to build URL for placementId: \(placementId)")
            callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidURL, errorMessage: Constants.ErrorMessages.failedToBuildURL)
            return
        }
        
        NetworkManager.shared.get(url: url) { result in
            switch result {
            case .success(let data):
                guard let htmlContent = String(data: data, encoding: .utf8) else {
                    callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidResponse, errorMessage: Constants.ErrorMessages.invalidResponse)
                    return
                }
                
                do {
                    if let jsonData = htmlContent.data(using: .utf8),
                       let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        // User override: if both adm and position are present, let user render
                        if let adm = json["adm"] as? String,
                           let positionValue = json["position"] as? Int,
                           let position = AdPosition(rawValue: positionValue) {
                            callback?.onAdRenderOverride(adm: adm, position: position)
                            return // Don't proceed with default rendering
                        }
                        
                        // Process position
                        if let positionValue = json["position"] as? Int,
                           let position = AdPosition(rawValue: positionValue) {
                            self.responseAdPosition = position
                        }
                        
                        // Process SKAdNetwork response if present
                        if let skadnetworkData = json["skadnetwork"] as? [String: Any] {
                            print("BidscubeSDK: Found SKAdNetwork data in response")
                            if let skadnetworkResponse = SKAdNetworkManager.parseSKAdNetworkResponse(from: skadnetworkData) {
                                print("BidscubeSDK: Successfully parsed SKAdNetwork response")
                                SKAdNetworkManager.processSKAdNetworkResponse(skadnetworkResponse)
                            } else {
                                print("BidscubeSDK: Failed to parse SKAdNetwork response")
                            }
                        } else {
                            print("BidscubeSDK: No SKAdNetwork data in response")
                        }
                    }
                } catch {
                    print("BidscubeSDK: Error parsing JSON response: \(error)")
                    self.responseAdPosition = .unknown
                }
                
                callback?.onAdLoaded(placementId)
                callback?.onAdDisplayed(placementId)
                
                // Track SKAdNetwork impression
                trackAdImpression()
                
            case .failure(let error):
                callback?.onAdFailed(placementId, errorCode: error.errorCode, errorMessage: error.localizedDescription)
            }
        }
    }

    public static func getImageAdView(_ placementId: String, _ callback: AdCallback?) -> UIView {
        print("🚀 DEBUG: getImageAdView called for placement: \(placementId)")
        Logger.info("getImageAdView called for placement: \(placementId)")
        
        
        let effectivePosition = getEffectiveAdPosition()
        let view: UIView
        
        if effectivePosition == .header || effectivePosition == .footer || effectivePosition == .sidebar {
            view = createOnMainThread { BannerAdView(position: effectivePosition) }
        } else {
            view = createOnMainThread { ImageAdView() }
        }
        
        callback?.onAdLoading(placementId)
        
        
        guard let url = buildRequestURL(placementId: placementId, adType: .image) else {
            Logger.error("Failed to build request URL for image ad")
            callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidURL, errorMessage: Constants.ErrorMessages.failedToBuildURL)
            return view
        }
        
        
        if let imageAdView = view as? ImageAdView {
            imageAdView.setPlacementInfo(placementId, callback: callback)
            imageAdView.loadAdFromURL(url)
        } else if let bannerAdView = view as? BannerAdView {
            bannerAdView.setPlacementInfo(placementId, callback: callback)
            bannerAdView.loadAdFromURL(url)
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.responseAdPosition = .unknown
            callback?.onAdLoaded(placementId)
            callback?.onAdDisplayed(placementId)
        }
        
        return view
    }

    public static func showVideoAd(_ placementId: String, _ callback: AdCallback?) {
        callback?.onAdLoading(placementId)
        
        // Build GET URL with SKAdNetwork parameters
        let includeSKAdNetworks = configuration?.enableSKAdNetwork ?? false
        
        guard let url = URLBuilder.buildAdRequestURL(placementId: placementId, adType: .video, position: getEffectiveAdPosition(), timeoutMs: configuration?.defaultAdTimeoutMs ?? Constants.defaultTimeoutMs, debug: configuration?.enableDebugMode ?? false, includeSKAdNetworks: includeSKAdNetworks) else {
            callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidURL, errorMessage: Constants.ErrorMessages.failedToBuildURL)
            return
        }
        
        NetworkManager.shared.get(url: url) { result in
            switch result {
            case .success(let data):
                guard let content = String(data: data, encoding: .utf8) else {
                    callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidResponse, errorMessage: Constants.ErrorMessages.invalidResponse)
                    return
                }
                
                
                do {
                    if let jsonData = content.data(using: .utf8),
                               let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let adm = json["adm"] as? String,
                               let positionValue = json["position"] as? Int,
                               let position = AdPosition(rawValue: positionValue) {
                                callback?.onAdRenderOverride(adm: adm, position: position)
                                return
                            }
                } catch {
                    self.responseAdPosition = .fullScreen
                }
                
                callback?.onAdLoaded(placementId)
                callback?.onAdDisplayed(placementId)
                callback?.onVideoAdStarted(placementId)
                callback?.onVideoAdCompleted(placementId)
                
            case .failure(let error):
                callback?.onAdFailed(placementId, errorCode: error.errorCode, errorMessage: error.localizedDescription)
            }
        }
    }

    public static func getVideoAdView(
        _ placementId: String,
        _ callback: AdCallback?
    ) -> UIView {
       
        let view = createOnMainThread { VideoAdView() }
        
        callback?.onAdLoading(placementId)
        
        
        let adType: AdType = .video
        guard let url = buildRequestURL(placementId: placementId, adType: adType) else {
            Logger.error("Failed to build request URL for \(adType)")
            callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidURL, errorMessage: Constants.ErrorMessages.failedToBuildURL)
            return view
        }
        
        
        if let videoAdView = view as? VideoAdView {
            videoAdView.setPlacementInfo(placementId, callback: callback)
            videoAdView.loadVideoAdFromURL(url)
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.responseAdPosition = .fullScreen
            callback?.onAdLoaded(placementId)
            callback?.onAdDisplayed(placementId)
            callback?.onVideoAdStarted(placementId)
            
           
            callback?.onVideoAdCompleted(placementId)
        }
        
        return view
    }


    public static func showNativeAd(_ placementId: String, _ callback: AdCallback?) {
        callback?.onAdLoading(placementId)
        
        // Build GET URL with SKAdNetwork parameters
        let includeSKAdNetworks = configuration?.enableSKAdNetwork ?? false
        
        guard let url = URLBuilder.buildAdRequestURL(placementId: placementId, adType: .native, position: getEffectiveAdPosition(), timeoutMs: configuration?.defaultAdTimeoutMs ?? Constants.defaultTimeoutMs, debug: configuration?.enableDebugMode ?? false, includeSKAdNetworks: includeSKAdNetworks) else {
            callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidURL, errorMessage: Constants.ErrorMessages.failedToBuildURL)
            return
        }
        
        NetworkManager.shared.get(url: url) { result in
            switch result {
            case .success(let data):
                guard let content = String(data: data, encoding: .utf8) else {
                    callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidResponse, errorMessage: Constants.ErrorMessages.invalidResponse)
                    return
                }
                
                
                do {
                    if let jsonData = content.data(using: .utf8),
                       let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        if let adm = json["adm"] as? String,
                           let positionValue = json["position"] as? Int,
                           let position = AdPosition(rawValue: positionValue) {
                            callback?.onAdRenderOverride(adm: adm, position: position)
                            return // Don't proceed with default rendering
                        }
                        // Process position
                        if let positionValue = json["position"] as? Int,
                           let position = AdPosition(rawValue: positionValue) {
                            self.responseAdPosition = position
                        }
                        
                        // Process SKAdNetwork response if present
                        if let skadnetworkData = json["skadnetwork"] as? [String: Any] {
                            print("🔍 BidscubeSDK: Found SKAdNetwork data in video response")
                            if let skadnetworkResponse = SKAdNetworkManager.parseSKAdNetworkResponse(from: skadnetworkData) {
                                print("BidscubeSDK: Successfully parsed SKAdNetwork response")
                                SKAdNetworkManager.processSKAdNetworkResponse(skadnetworkResponse)
                            } else {
                                print("BidscubeSDK: Failed to parse SKAdNetwork response")
                            }
                        } else {
                            print("ℹ️ BidscubeSDK: No SKAdNetwork data in video response")
                        }
                    }
                } catch {
                    print("❌ BidscubeSDK: Error parsing video JSON response: \(error)")
                    self.responseAdPosition = .unknown
                }
                
                callback?.onAdLoaded(placementId)
                callback?.onAdDisplayed(placementId)
                
            case .failure(let error):
                callback?.onAdFailed(placementId, errorCode: error.errorCode, errorMessage: error.localizedDescription)
            }
        }
    }

    public static func getNativeAdView(_ placementId: String, _ callback: AdCallback?) -> UIView {
        Logger.info("getNativeAdView called for placement: \(placementId)")
        
        let view: NativeAdView = createOnMainThread { NativeAdView() }
        
        callback?.onAdLoading(placementId)
        
        
        guard let url = buildRequestURL(placementId: placementId, adType: .native) else {
            Logger.error("Failed to build request URL for native ad")
            callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidURL, errorMessage: Constants.ErrorMessages.failedToBuildURL)
            return view
        }
        
        
        view.setPlacementInfo(placementId, callback: callback)
        view.loadNativeAdFromURL(url)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.responseAdPosition = .unknown
            callback?.onAdLoaded(placementId)
            callback?.onAdDisplayed(placementId)
        }
        
        return view
    }
    
    
    
    
    public static func presentImageAd(_ placementId: String, from viewController: UIViewController, callback: AdCallback? = nil) {
        AdViewController.presentAd(placementId: placementId, adType: .image, from: viewController, callback: callback)
    }
    
    
    public static func pushImageAd(_ placementId: String, onto navigationController: UINavigationController, callback: AdCallback? = nil) {
        AdViewController.pushAd(placementId: placementId, adType: .image, onto: navigationController, callback: callback)
    }
    
    
    public static func presentVideoAd(_ placementId: String, from viewController: UIViewController, callback: AdCallback? = nil) {
        AdViewController.presentAd(placementId: placementId, adType: .video, from: viewController, callback: callback)
    }
    
    
    public static func pushVideoAd(_ placementId: String, onto navigationController: UINavigationController, callback: AdCallback? = nil) {
        AdViewController.pushAd(placementId: placementId, adType: .video, onto: navigationController, callback: callback)
    }
    
    
    public static func presentNativeAd(_ placementId: String, from viewController: UIViewController, callback: AdCallback? = nil) {
        AdViewController.presentAd(placementId: placementId, adType: .native, from: viewController, callback: callback)
    }
    
    
    public static func pushNativeAd(_ placementId: String, onto navigationController: UINavigationController, callback: AdCallback? = nil) {
        AdViewController.pushAd(placementId: placementId, adType: .native, onto: navigationController, callback: callback)
    }
    
    
    
    
    public static func getAdViewController(_ placementId: String, _ adType: AdType, _ callback: AdCallback?) -> UIViewController {
        Logger.info("getAdViewController called for placement: \(placementId), type: \(adType)")
        
        return createOnMainThread {
            AdViewController(placementId: placementId, adType: adType, callback: callback)
        }
    }
    
    
    public static func presentAd(_ placementId: String, _ adType: AdType, from viewController: UIViewController, _ callback: AdCallback?) {
        Logger.info("presentAd called for placement: \(placementId), type: \(adType)")
        
        AdViewController.presentAd(placementId: placementId, adType: adType, from: viewController, callback: callback)
    }
    
    
    public static func shouldPresentFullScreen(_ placementId: String, _ adType: AdType, _ callback: AdCallback?) -> Bool {
        
        if let manualPosition = manualAdPosition, manualPosition == .fullScreen {
            return true
        }
        
        
        if responseAdPosition == .fullScreen {
            return true
        }
        
        
        
        return responseAdPosition == .unknown
    }
    
    
    
    
    public static func getBannerAdView(_ placementId: String, position: AdPosition, callback: AdCallback?) -> BannerAdView {
        Logger.info("getBannerAdView called for placement: \(placementId), position: \(position)")
        
        let bannerView = createOnMainThread { BannerAdView(position: position) }
        
        callback?.onAdLoading(placementId)
        
        
        guard let url = buildRequestURL(placementId: placementId, adType: .image) else {
            Logger.error("Failed to build request URL for banner ad")
            callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidURL, errorMessage: Constants.ErrorMessages.failedToBuildURL)
            return bannerView
        }
        
        
        bannerView.setPlacementInfo(placementId, callback: callback)
        bannerView.loadAdFromURL(url)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.responseAdPosition = position
            callback?.onAdLoaded(placementId)
            callback?.onAdDisplayed(placementId)
        }
        
        return bannerView
    }
    
    
    public static func showHeaderBanner(_ placementId: String, in viewController: UIViewController, callback: AdCallback? = nil) {
        Logger.info("showHeaderBanner called for placement: \(placementId)")
        
        let bannerView = getBannerAdView(placementId, position: .header, callback: callback)
        trackBanner(bannerView)
        bannerView.attachToScreen(in: viewController)
    }
    
    
    public static func showFooterBanner(_ placementId: String, in viewController: UIViewController, callback: AdCallback? = nil) {
        Logger.info("showFooterBanner called for placement: \(placementId)")
        
        let bannerView = getBannerAdView(placementId, position: .footer, callback: callback)
        trackBanner(bannerView)
        bannerView.attachToScreen(in: viewController)
    }
    
    
    public static func showSidebarBanner(_ placementId: String, in viewController: UIViewController, callback: AdCallback? = nil) {
        Logger.info("showSidebarBanner called for placement: \(placementId)")
        
        let bannerView = getBannerAdView(placementId, position: .sidebar, callback: callback)
        trackBanner(bannerView)
        bannerView.attachToScreen(in: viewController)
    }
    
    
    public static func showCustomBanner(_ placementId: String, position: AdPosition, width: CGFloat, height: CGFloat, in viewController: UIViewController, callback: AdCallback? = nil) {
        Logger.info("showCustomBanner called for placement: \(placementId), position: \(position), size: \(width)x\(height)")
        
        let bannerView = getBannerAdView(placementId, position: position, callback: callback)
        trackBanner(bannerView)
        bannerView.setBannerDimensions(width: width, height: height)
        bannerView.attachToScreen(in: viewController)
    }
    
    
    public static func getBannerAdView(_ placementId: String, position: AdPosition, cornerRadius: CGFloat, callback: AdCallback?) -> BannerAdView {
        Logger.info("getBannerAdView called for placement: \(placementId), position: \(position), cornerRadius: \(cornerRadius)")
        
        let bannerView = createOnMainThread { BannerAdView(position: position, cornerRadius: cornerRadius) }
        
        callback?.onAdLoading(placementId)
        
        
        guard let url = buildRequestURL(placementId: placementId, adType: .image) else {
            Logger.error("Failed to build request URL for banner ad")
            callback?.onAdFailed(placementId, errorCode: Constants.ErrorCodes.invalidURL, errorMessage: Constants.ErrorMessages.failedToBuildURL)
            return bannerView
        }
        
        
        bannerView.setPlacementInfo(placementId, callback: callback)
        bannerView.loadAdFromURL(url)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.responseAdPosition = position
            callback?.onAdLoaded(placementId)
            callback?.onAdDisplayed(placementId)
        }
        
        return bannerView
    }
    
    
    public static func showBannerWithCornerRadius(_ placementId: String, position: AdPosition, cornerRadius: CGFloat, in viewController: UIViewController, callback: AdCallback? = nil) {
        Logger.info("showBannerWithCornerRadius called for placement: \(placementId), position: \(position), cornerRadius: \(cornerRadius)")
        
        let bannerView = getBannerAdView(placementId, position: position, cornerRadius: cornerRadius, callback: callback)
        trackBanner(bannerView)
        bannerView.attachToScreen(in: viewController)
    }
    
    
    public static func showCustomBanner(_ placementId: String, position: AdPosition, width: CGFloat, height: CGFloat, cornerRadius: CGFloat, in viewController: UIViewController, callback: AdCallback? = nil) {
        Logger.info("showCustomBanner called for placement: \(placementId), position: \(position), size: \(width)x\(height), cornerRadius: \(cornerRadius)")
        
        let bannerView = getBannerAdView(placementId, position: position, cornerRadius: cornerRadius, callback: callback)
        trackBanner(bannerView)
        bannerView.setBannerDimensions(width: width, height: height)
        bannerView.attachToScreen(in: viewController)
    }
    
    
    
    
    private static func trackBanner(_ banner: BannerAdView) {
        activeBanners.append(banner)
        Logger.debug("Tracking banner ad. Total active banners: \(activeBanners.count)")
    }
    
    
    public static func untrackBanner(_ banner: BannerAdView) {
        activeBanners.removeAll { $0 === banner }
        Logger.debug("Untracking banner ad. Total active banners: \(activeBanners.count)")
    }
    
    
    public static func removeAllBanners() {
        Logger.debug("Removing all active banners. Count: \(activeBanners.count)")
        
        for banner in activeBanners {
            banner.detachFromScreen()
        }
        
        activeBanners.removeAll()
        Logger.debug("All banners removed")
    }
    
    
    public static func getActiveBannerCount() -> Int {
        return activeBanners.count
    }
    
    // MARK: - SKAdNetwork Methods
    
    private static func initializeSKAdNetwork(config: SDKConfig) {
        if #available(iOS 14.0, *) {
            SKAdNetworkManager.registerForAdNetworkAttribution()
            
            if let networkId = config.skAdNetworkId {
                Logger.info("SKAdNetwork initialized with network ID: \(networkId)")
            }
            
            if config.skAdNetworkConversionValue > 0 {
                SKAdNetworkManager.updateConversionValue(config.skAdNetworkConversionValue)
            }
        } else {
            Logger.info("SKAdNetwork not available on this iOS version")
        }
    }
    
    public static func trackAdImpression() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackAdImpression()
        }
    }
    
    public static func trackAdClick() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackAdClick()
        }
    }
    
    public static func trackAppOpen() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackAppOpen()
        }
    }
    
    public static func trackUserRegistration() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackUserRegistration()
        }
    }
    
    public static func trackFirstPurchase() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackFirstPurchase()
        }
    }
    
    public static func trackSubscription() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackSubscription()
        }
    }
    
    public static func trackHighValuePurchase() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackHighValuePurchase()
        }
    }
    
    public static func trackRetention() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackRetention()
        }
    }
    
    public static func trackEngagement() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackEngagement()
        }
    }
    
    public static func trackPremiumFeature() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackPremiumFeature()
        }
    }
    
    public static func trackSocialShare() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackSocialShare()
        }
    }
    
    public static func trackReferral() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackReferral()
        }
    }
    
    public static func trackLoyaltyProgram() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackLoyaltyProgram()
        }
    }
    
    public static func trackPremiumSubscription() {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            ConversionTracker.trackPremiumSubscription()
        }
    }
    
    public static func updateConversionValue(_ value: Int) {
        guard let config = configuration, config.enableSKAdNetwork else { return }
        
        if #available(iOS 14.0, *) {
            SKAdNetworkManager.updateConversionValue(value)
        }
    }
    
    public static func getSKAdNetworkStatus() -> String {
        if #available(iOS 14.0, *) {
            return SKAdNetworkManager.getAttributionStatus()
        } else {
            return "not_available"
        }
    }
    
    // MARK: - SKAdNetwork Public API
    
    /// Register SKAdNetwork for ad attribution
    /// - Parameters:
    ///   - adNetworkId: The SKAdNetwork identifier
    ///   - completion: Completion handler with success status
    public static func registerSKAdNetwork(_ adNetworkId: String, completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.0, *) {
            SKAdNetworkManager.registerForAdNetworkAttribution()
            completion(true)
        } else {
            completion(false)
        }
    }
    
    /// Track ad view event with SKAdNetwork
    /// - Parameter completion: Completion handler with success status
    public static func trackAdView(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.0, *) {
            SKAdNetworkManager.trackAdImpression()
            completion(true)
        } else {
            completion(false)
        }
    }
    
    /// Track ad click event with SKAdNetwork
    /// - Parameter completion: Completion handler with success status
    public static func trackAdClick(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.0, *) {
            SKAdNetworkManager.trackAdClick()
            completion(true)
        } else {
            completion(false)
        }
    }
    
    /// Track ad interaction event with SKAdNetwork
    /// - Parameter completion: Completion handler with success status
    public static func trackAdInteraction(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.0, *) {
            SKAdNetworkManager.trackAdClick()
            completion(true)
        } else {
            completion(false)
        }
    }
    
    /// Update SKAdNetwork conversion value
    /// - Parameters:
    ///   - conversionValue: The conversion value (0-63)
    ///   - completion: Completion handler with success status
    public static func updateSKAdNetworkConversionValue(_ conversionValue: Int, completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.0, *) {
            SKAdNetworkManager.updateConversionValue(conversionValue)
            completion(true)
        } else {
            completion(false)
        }
    }
    
    /// Check if SKAdNetwork is available
    /// - Returns: True if SKAdNetwork is available
    public static func isSKAdNetworkAvailable() -> Bool {
        return SKAdNetworkManager.isAvailable()
    }
    
    /// Get all SKAdNetwork IDs from the app's Info.plist
    /// - Returns: Array of SKAdNetwork identifiers
    public static func getSKAdNetworkIDs() -> [String] {
        return SKAdNetworkManager.getSKAdNetworkIDs()
    }
    
    /// Display SKAdNetwork IDs in console
    public static func displaySKAdNetworkIDsInConsole() {
        SKAdNetworkManager.displaySKAdNetworkIDsInConsole()
    }
    
    /// Get SKAdNetwork IDs as formatted string for display
    /// - Returns: Formatted string with all SKAdNetwork IDs
    public static func getSKAdNetworkIDsAsString() -> String {
        return SKAdNetworkManager.getSKAdNetworkIDsAsString()
    }
    
    /// Debug method to inspect Info.plist structure
    /// - Returns: Detailed information about Info.plist contents
    public static func debugInfoPlistStructure() -> String {
        return SKAdNetworkManager.debugInfoPlistStructure()
    }
}


