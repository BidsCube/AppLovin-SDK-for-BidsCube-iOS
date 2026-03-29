/*! \file IMAUiElements.h
 * GoogleIMA3
 *
 * Copyright (c) 2013 Google Inc. All rights reserved.
 *
 * Defines an enum containing the possible UI elements that can be
 * customized by the publisher during ad playback.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark IMAUiElementType

/**
 * Ad UI elements you can customize in your app. Ignore this enum for tvOS. The tvOS IMA SDK does
 * not support the
 * <a href="../Classes/IMAAdsRenderingSettings#uielements"><code>IMAAdsRenderingSettings.uiElements</code></a>
 * parameter.
 */
typedef NS_ENUM(NSInteger, IMAUiElementType) {
  /**
   * Ad attribution UI element.
   */
  kIMAUiElements_AD_ATTRIBUTION,
  /**
   * Ad countdown element.
   */
  kIMAUiElements_COUNTDOWN
};

NS_ASSUME_NONNULL_END
