#import <UIKit/UIKit.h>

/// Posted once after `Adjust initSdk` — home retries adid upload if it ran too early.
FOUNDATION_EXPORT NSNotificationName const HFAdjustDidInitNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

/// ATT chain — call only after network boot (06) succeeds.
- (void)hf_appRequestATTIfNeeded;
/// Flush pending IDFA bury after 06 ready.
- (void)hf_appFlushIdfaTrace;
/// YES after Adjust `initSdk`.
- (BOOL)hf_adjustReady;

@end
