#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Interface to describe a base UI element.
 * :nodoc:
 */
@interface IMAUIElement : NSObject
/**
 * The UI element ID. Used in communication with the SDK over the element lifecycle and interaction
 * (Shown and click events.)
 * :nodoc:
 */
@property(nonatomic, readonly) NSString *ID;

/**
 * Indicates if the element is required or optional. If true the element is required to be rendered.
 * If false, it is optional to render the element or not. Default is false.
 * :nodoc:
 */
@property(nonatomic, readonly, getter=isRequired) BOOL required;

/**
 * :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;
@end

/**
 * Interface to describe a non-interactive text UI element.
 * :nodoc:
 */
@interface IMAUILabel : IMAUIElement
/**
 * Localized text to display inside the label.
 * :nodoc:
 */
@property(nonatomic, readonly) NSString *text;

/**
 * :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;
@end

/**
 * Interface to describe an interactive button UI element.
 * :nodoc:
 */
@interface IMAUIButton : IMAUILabel
/**
 * :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;
@end

/**
 * Interface to describe an interactive link element.
 * :nodoc:
 */
@interface IMAUILink : IMAUILabel
/**
 * External URL to navigate to when the element is clicked.
 * :nodoc:
 */
@property(nonatomic, readonly) NSURL *clickURL;

/**
 * :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;
@end

/**
 * Interface to describe an image asset.
 * :nodoc:
 */
@interface IMAUIImage : NSObject
/**
 * The image URL.
 * :nodoc:
 */
@property(nonatomic, readonly) NSURL *URL;

/**
 * The image alt text.
 * :nodoc:
 */
@property(nonatomic, nullable, readonly) NSString *altText;

/**
 * Pixel width of the image asset.
 * :nodoc:
 */
@property(nonatomic, readonly) NSInteger width;

/**
 * Pixel height of the image asset.
 * :nodoc:
 */
@property(nonatomic, readonly) NSInteger height;

/**
 * :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;
@end

/**
 * Fallback image UI element, extending the UI Image interface.
 * Used to display icon fallback image asset.
 * :nodoc:
 */
@interface IMAUIFallbackImage : IMAUIImage
/**
 * The UI element ID. Used in communication with the SDK over the element lifecycle and interaction
 * (Shown and click events.)
 * :nodoc:
 */
@property(nonatomic, readonly) NSString *ID;

/**
 * The fallback image program. (Matching the entry in the VAST icon program attribute.)
 * :nodoc:
 */
@property(nonatomic, readonly) NSString *program;

/**
 * :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;
@end


/**
 * Interface to describe an icon UI element.
 * :nodoc:
 */
@interface IMAUIIcon : IMAUIElement
/**
 * External URL to navigate to when the element is clicked.
 * :nodoc:
 */
@property(nonatomic, nullable, readonly) NSURL *clickURL;

/**
 * The icon image asset.
 * :nodoc:
 */
@property(nonatomic, readonly) IMAUIImage *image;

/**
 * Indicates whether the icon is interactive or not.
 * :nodoc:
 */
@property(nonatomic, readonly, getter=isClickable) BOOL clickable;

/**
 * :nodoc:
 */

- (instancetype)init NS_UNAVAILABLE;
@end

/**
 * Interface to describe a VAST icon UI element.
 * :nodoc:
 */
@interface IMAUIVASTIcon : IMAUIIcon
/**
 * The VAST icon program. (Matching the entry in the VAST icon program attribute.)
 * :nodoc:
 */
@property(nonatomic, readonly) NSString *program;

/**
 * List of UI fallback images.
 * :nodoc:
 */
@property(nonatomic, readonly) NSArray<IMAUIFallbackImage *> *fallbackImages;

/**
 * The icon x position in pixels or a string representing the image horizontal positioning
 * left | right.
 * :nodoc:
 */
@property(nonatomic, nullable, readonly) NSString *xPosition;

/**
 * The icon y position in pixels or a string representing the image vertical positioning
 * top | bottom.
 * :nodoc:
 */
@property(nonatomic, nullable, readonly) NSString *yPosition;

/**
 * :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;
@end

/**
 * The skip UI element is composed from a countdown label and a skip button.
 * :nodoc:
 */
@interface IMAUISkip : NSObject
/**
 * Button that enables the viewer to skip the ad when the ad timeline reaches the ad skip offset.
 * :nodoc:
 */
@property(nonatomic, readonly) IMAUIButton *button;

/**
 * View that displays the countdown until the ad becomes skippable. The ad must not be skippable
 * until the skip offset time is met; during this unskippable period, a notice must be displayed to
 * the user informing them that the ad can be skipped in X seconds.
 * :nodoc:
 */
@property(nonatomic, readonly) IMAUILabel *countdown;

/**
 * :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;
@end

/**
 * Interface to describe a custom ad UI configuration for a single ad.
 * :nodoc:
 */
@interface IMACustomUIConfig : NSObject
/**
 * A transparent UI element overlaying the video and matching its dimensions, used to trigger
 * clickthrough events. The element must be placed above the player z-index and below other UI
 * elements.
 * :nodoc:
 */
@property(nonatomic, readonly, nullable) IMAUIElement *videoOverlay;

/**
 * Call to action UI button, used to trigger clickthrough events.
 * :nodoc:
 */
@property(nonatomic, readonly, nullable) IMAUIButton *callToAction;

/**
 * Advertisement (or Ad) UI label, letting viewers know that the content they are consuming
 * is an advertisement.
 * :nodoc:
 */
@property(nonatomic, readonly, nullable) IMAUILabel *attribution;

/**
 * The UI skip element is composed from a countdown label and a skip button. Absent if the ad is not
 * skippable.
 * :nodoc:
 */
@property(nonatomic, readonly, nullable) IMAUISkip *skip;

/**
 * A list of UI VAST Icons. Only icons with a program attribute specified in the VAST will be
 * provided, if multiple icons with the same program are listed, the first icon will be returned.
 * Clickable and required icons (such as the Google About this Ad icon) are provided with a click
 * URL and a list of fallback images.
 * :nodoc:
 */
@property(nonatomic, readonly) NSArray<IMAUIVASTIcon *> *icons;

/**
 * The ad title UI Link, if provided by the advertiser. A click URL is included for the ad
 * title element that points to the ad content on YouTube. On click open a new browser tab with the
 * url (on platforms with a browser window. No action is needed in browser-less environments.)
 * :nodoc:
 */
@property(nonatomic, readonly, nullable) IMAUILink *adTitle;

/**
 * The ad author avatar UI Icon. A click URL is included for the ad author icon element that
 * points to the author's YouTube channel page. On click open a new browser tab with the url (on
 * platforms with a browser window. No action is needed in browser-less environments.)
 * :nodoc:
 */
@property(nonatomic, readonly, nullable) IMAUIIcon *authorIcon;

/**
 * The ad author name. A click URL is included for the ad author name element that points to the
 * author's YouTube channel page. On click open a new browser tab with the url (on platforms with
 * a browser window. No action is needed in browser-less environments.)
 * :nodoc:
 */
@property(nonatomic, readonly, nullable) IMAUILink *authorName;

/**
 * :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
