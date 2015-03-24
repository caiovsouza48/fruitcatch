/*!
 * @header
 *
 * @discussion Header file containing the main public API.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PulseSDK/PulseTimer.h>

/*!
 * Use the build number instead of the marketing release number when
 * reporting events.  The associated value should be a boolean \c
 * NSNumber instance.  Defaults to \c \@NO.
 */
extern NSString * const PulseUseBuildNumberForVersion;

/*!
 * Disable automatic monitoring of UIActivityIndicatorView instances.
 * The associated value should be a boolean \c NSNumber instance.
 * Defaults to \c \@NO.
 */
extern NSString * const PulseDisableAutomaticSpinners;

/*!
 * Disable tracing for the majority of iOS.
 * The associated value should be a boolean \c NSNumber instance.
 * Defaults to \c \@NO.
 */
extern NSString * const PulseDisableTracing;

/*!
 * @class PulseSDK
 *
 * @abstract The main public interface to the Pulse SDK.
 *
 * @author Keith Simmons
 */
@interface PulseSDK : NSObject

/*!
 * @abstract Initialize the Pulse.io monitoring system.
 *
 * @discussion This should be called within an autorelease pool
 *   context but before any other calls are made.
 *
 * @param applicationID The API key provided by Pulse.io
 *
 * @see +[PulseSDK monitor:options:]
 */
+ (void)monitor:(NSString *)applicationID;

/*!
 * @abstract Initialize the Pulse.io monitoring system.
 *
 * @discussion This should be called within an autorelease pool
 *   context but before any other calls are made.
 *
 * @param applicationID The API key provided by Pulse.io
 *
 * @param options An optional dictionary of options to control the
 *   SDK.  This dictionary will be copied.
 */
+ (void)monitor:(NSString *)applicationID options:(NSDictionary *)options;

/*!
 * @abstract Have the SDK trace all instance methods of the given
 *   class.
 *
 * @discussion All instance methods except for @link //apple_ref/occ/instm/NSObject/dealloc dealloc @/link of
 *   the class will be traced.
 *
 * @param cls The class whose methods should be traced
 */
+ (void)instrumentClass:(Class)cls;

/*!
 * @abstract Have the SDK trace a specific instance method of a class
 *
 * @discussion Trace all calls to a particular class and selector combination.
 *   The method should not be dealloc, and it must be an instance method.
 *
 * @param cls The class whose method should be traced
 * 
 * @param sel The selector that should be traced
 */
+ (void) instrumentClass:(Class)cls selector:(SEL)sel;

/*!
 * @abstract Specify a user label for the most recent touch.
 *
 * @discussion This will supercede any automatically generated label.
 *
 * @param label The label to assign
 */
+ (void)labelTouch:(NSString *)label DEPRECATED_MSG_ATTRIBUTE("Use +[PulseSDK nameUserAction:] instead");

/*!
 * @abstract Specify a label for the most recent user action.
 *
 * @discussion This will supercede any automatically generated label.
 *
 * @param name The label to assign
 */
+ (void)nameUserAction:(NSString *)name;

/*!
 * @abstract Start a timer by name.
 *
 *   Note: These timers should only be uesd for tracking foreground activity.
 *   For timing background activites, see startBackgroundTimer:
 *
 * @param name The name of the timer
 *
 * @return The timer with the given name
 */
+ (PulseTimer *)startTimer:(NSString *)name;

/*!
 * @abstract Start a special type of timer that can track background processing.  
 *   Ordinary timers are discarded when they start in the foreground but continue 
 *   running in the background.  This avoids erroneous times from suspended code.
 *   However, if you specifically want to track code execution in the background,
 *   use this call.
 *
 * @param name The name of the timer
 *
 * @return The timer with the given name
 */
+ (PulseTimer *)startBackgroundTimer:(NSString *)name;

/*!
 * @abstract Stop a timer by name.  Can be used by timers started with either
 *   \c startTimer: or \c startBackgroundTimer:
 *
 * @param name The name of the timer
 */
+ (void)stopTimer:(NSString *)name;

/*!
 * @abstract Begin a user-specified wait period.
 *
 * @discussion This method should be balanced with a
 *   \c stopWait: call. If this method is called a second
 *   time with the same key and without an intervening
 *   \c stopWait: call, it has no effect.
 *
 * @param key The key to use when specifying the end of the period
 */
+ (void)startWait:(NSString *)key DEPRECATED_ATTRIBUTE;

/*!
 * @abstract End a user-specified wait period.
 *
 * @discussion If there has not been a previous call to
 *   \c startWait: with the given key, this call has no effect.
 *
 * @param key The key that was used to start the wait period
 */
+ (void)stopWait:(NSString *)key DEPRECATED_ATTRIBUTE;

/*!
 * @abstract Begin a user-specified wait period corresponding to a
 * specific touch event.
 *
 * @discussion This method should be balanced with a
 *   \c stopWait: call. If this method is called a second
 *   time with the same key and without an intervening
 *   \c stopWait: call, it has no effect.
 *
 * @param key The key to use when specifying the end of the period
 * @param touch The name of the touch event to associate with the wait
 */
+ (void)startWait:(NSString *)key withTouch:(NSString *)touch DEPRECATED_ATTRIBUTE;

/*!
 * @abstract Notify the SDK that a custom activity indicator has
 *   started animating.
 *
 * @discussion A spinner whose visibility state is not explicitly
 *   tracked must have a corresponding \c stopSpinner: call.  Tracked
 *   spinners need not call \c stopSpinner: as monitoring will cease
 *   once the spinner has gone out of scope.
 *
 * @param spinner The view to use as an activity indicator
 *
 * @param track \c YES if changes to the view’s visibility should
 *   be reflected as changes to its animation state
 */
+ (void)startSpinner:(UIView *)spinner trackVisibility:(BOOL)track;

/*!
 * @abstract Notify the SDK that a custom activity indicator has
 *   started animating.  Equivalent to calling
 *   \c +[PulseSDK startSpinner:trackVisibility:]
 *   with a track value of \c YES.  Must be balanced with a call
 *   to \c stopSpinner: before an event will be generated.
 *
 * @param spinner The view of the activity indicator
 */
+ (void)startSpinner:(UIView *)spinner;

/*!
 * @abstract Notify the SDK that a custom activity indicator has
 *   stopped animating.
 *
 * @param spinner The view of the activity indicator
 */
+ (void)stopSpinner:(UIView *)spinner;

/*!
 * @abstract Notify the SDK that an activity indicator should not
 *   introduce a wait state.
 *
 * @param spinner The object that may be interpreted as an activity
 *   indicator
 *
 * @param disabled <code>YES</code> if the spinner should be ignored
 *   for the purposes of generating wait states; <code>NO</code>
 *   to treat it as a regular spinner
 */
+ (void)spinner:(UIView *)spinner setIgnored:(BOOL)disabled;

/*!
 * @abstract Check the ignored flag of an activity indicator.
 *
 * @param spinner The object that may be interpreted as an activity
 *   indicator
 */
+ (BOOL)isSpinnerIgnored:(UIView *)spinner;

/*!
 * @abstract Property controlling the stripping of query and parameter strings from recorded URLs.
 * @param enabled True if query and parameter strings should be stripped from URLs before they are recorded.
 */
+ (void)setURLStrippingEnabled:(BOOL)enabled;

/*!
 * @abstract If true, query and parameter strings should be stripped from URLs before they are recorded.
 */
+ (BOOL)URLStrippingEnabled;

/*!
 * @abstract Return the user property associated with the given key.
 * @param key The name of the user property to fetch. Must not be @c nil.
 * @return The value of the user property, or @c nil if no such property exists.
 * @see +[PulseSDK setUserPropertyValue:forKey:]
 */
+ (NSString *)userPropertyValueForKey:(NSString *)key;

/*!
 * @abstract Set a user property value for a given key.
 * @discussion Once set, user properties stay in effect until explicitly set to another value.
 * @param value The new value for the user property. Must not be @c nil.
 * @param key The name of the user property to set. Must not be @c nil.
 * @see +[PulseSDK userPropertyValueForKey:]
 */
+ (void)setUserPropertyValue:(NSString *)value forKey:(NSString *)key;

/*!
 * @abstract Listener block for responding to new user actions (see registerUserActionListener:)
 *
 * @param label The name of the user action
 * @param oldLabel The previous label for this user action (i.e. it's being relabeled).  Nil if this is a new user action.
 */
typedef void (^PulseUserActionLabelListener)(NSString *label, NSString *oldLabel);

/*!
 * @abstract Register a listener which is notified when a new user action is identified and labeled.
 *   Intended to be used for debugging.  This is a beta API call and may be removed in future versions of the SDK.
 *
 * @param listener A handler block invoked each time a new user action is identified and labeled.  Can be called
 *   multiple times for the same user action if the user action is re-labeled.
 */

+ (void) registerUserActionListener:(PulseUserActionLabelListener)listener;

@end
