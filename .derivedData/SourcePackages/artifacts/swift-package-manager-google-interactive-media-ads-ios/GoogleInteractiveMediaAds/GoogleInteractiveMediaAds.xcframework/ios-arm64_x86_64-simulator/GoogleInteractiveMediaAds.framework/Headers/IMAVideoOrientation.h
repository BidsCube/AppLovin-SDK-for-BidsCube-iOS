#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - IMAVideoOrientation

/**
 * Types of video orientations.
 * :nodoc:
 */
typedef NS_ENUM(NSInteger, IMAVideoOrientation) {
    IMAVideoOrientationUnset,
    IMAVideoOrientationLandscape,
    IMAVideoOrientationPortrait,
    IMAVideoOrientationSquare
} NS_SWIFT_NAME(VideoOrientation);

NS_ASSUME_NONNULL_END
