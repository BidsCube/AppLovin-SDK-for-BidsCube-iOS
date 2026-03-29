#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Request level UI options for ad UI.
 * Determines what features are supported. When a new feature is added it will be listed here,
 * defaulting its support to false.
 * :nodoc:
 */
@interface IMACustomUIOptions : NSObject
/**
 * Support for rendering skippable ads UI that includes an interactive skip button accessible via
 * cursor/touch or remote control. Defaults to false.
 * :nodoc:
 */
@property(nonatomic, getter=isSkippableSupported) BOOL skippableSupported;

/**
 * Support for displaying ads with an 'About This Ad' icon. A click on the icon must either open a
 * new browser window or render a fallback image modal. Defaults to false.
 * :nodoc:
 */
@property(nonatomic, getter=isAboutThisAdSupported) BOOL aboutThisAdSupported;

@end

NS_ASSUME_NONNULL_END
