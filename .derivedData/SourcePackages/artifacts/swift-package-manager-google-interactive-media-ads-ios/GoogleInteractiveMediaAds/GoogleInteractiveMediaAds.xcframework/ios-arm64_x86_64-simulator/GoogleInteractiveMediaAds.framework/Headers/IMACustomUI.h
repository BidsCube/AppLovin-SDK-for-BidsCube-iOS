#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class IMACustomUIConfig;

/**
 * Custom Ad UI.
 * Interface for the ad UI data provided by the stream manager.
 * Used to manage custom UI interaction and provide the custom UI config.
 * :nodoc:
 */
@interface IMACustomUI : NSObject

/**
 * Returns the custom ad UI config for the current ad. The UI config is an object containing
 * the data required to render UI elements for a specific ad.
 * :nodoc:
 */
@property(nonatomic, readonly) IMACustomUIConfig *config;

/**
 * Visibility API. When a UI element becomes visible, pass a reference of its ID and UIView
 * (where available) to the SDK, to assure that tracking events and reporting for the element are
 * set properly. Each element should be set on the visibleUIElements dictionary when it is visible
 * on the screen. Update this property any time the set of visible UI elements changes, passing in
 * the entire set of visible UI elements. Any elements omitted from this set are understood to not
 * be visible. The SDK will drop references to the old set of UI elements and only keep references
 * to the new set passed in. Passing in an empty array for instance, causes the SDK to drop all
 * references and understand that no UI elements are currently visible.
 * :nodoc:
 */
@property(nonatomic, readwrite) NSDictionary<NSString *, id> *visibleUIElements;

/**
 * Interactivity API. When a user clicks/touches a clickable element, pass a reference to the
 * click event (where available) with the element UI ID to the SDK for event tracking and SDK
 * controlled interactivity.
 * :nodoc:
 */
- (void)UIElement:(NSString *)ID didClickWithEvent:(nullable UIEvent *)event;

@end

NS_ASSUME_NONNULL_END
