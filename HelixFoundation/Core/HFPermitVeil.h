#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HFPermitKind) {
    HFPermitKindLocate = 0,  // Location
    HFPermitKindRoster,      // Contacts
    HFPermitKindLens,        // Camera
    HFPermitKindVisage       // Face ID
};

/// 8.1 / 10.1 §6.0.1 — secondary permission explain dialogs
@interface HFPermitVeil : NSObject

+ (NSString *)hf_permitAppName;
+ (NSString *)hf_permitBody:(HFPermitKind)kind;
+ (NSString *)hf_permitTitle:(HFPermitKind)kind;

/// Window-level sheet (location / contacts). Confirm → Settings.
+ (id)hf_permitPresent:(HFPermitKind)kind
               confirm:(nullable void (^)(void))onConfirm
                cancel:(nullable void (^)(void))onCancel;

+ (void)hf_permitDismiss:(nullable id)token;

/// Overlay pinned on a host view (camera → WebView). Confirm → Settings.
/// Returns the overlay view (pass to `hf_permitDismissHost:`).
+ (UIView *)hf_permitPresentOnHost:(UIView *)host
                              kind:(HFPermitKind)kind
                           confirm:(nullable void (^)(void))onConfirm
                            cancel:(nullable void (^)(void))onCancel;

+ (void)hf_permitDismissHost:(nullable UIView *)overlay;

@end

NS_ASSUME_NONNULL_END
