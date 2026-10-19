#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HFCurtainTier) {
    HFCurtainTierVeryLow = 0,
    HFCurtainTierLow,
    HFCurtainTierMid,
    HFCurtainTierHigh
};

/// Config for design-aligned general dialog
@interface HFCurtainSheet : NSObject
@property (nonatomic, copy, nullable) NSString *titleText;       // optional
@property (nonatomic, copy, nullable) NSString *bodyText;
@property (nonatomic, strong, nullable) UIView *extraView;       // optional custom area
@property (nonatomic, copy, nullable) NSString *leftTitle;       // secondary beige; nil => single button
@property (nonatomic, copy, nullable) NSString *rightTitle;      // primary orange (or the only button)
@property (nonatomic, assign) BOOL showClose;                    // default NO; uses two_icon_del
@property (nonatomic, assign) BOOL tapOutsideToClose;            // default NO
@property (nonatomic, assign) BOOL autoCloseOnAction;            // default YES
@property (nonatomic, assign) BOOL requireDoubleClose;           // close button needs 2 taps (reloan)
@property (nonatomic, assign) BOOL hf_closeArmed;                // runtime: first close tap seen
@property (nonatomic, assign) HFCurtainTier tier;                // default Mid
@property (nonatomic, copy, nullable) void (^onLeft)(void);
@property (nonatomic, copy, nullable) void (^onRight)(void);
@property (nonatomic, copy, nullable) void (^onClose)(void);
@end

@interface HFCurtainBox : NSObject

+ (instancetype)shared;

- (id)hf_curtainMask:(NSString *)text tier:(HFCurtainTier)tier;
- (void)hf_curtainDismiss:(id)token;

/// Design general dialog (title / body / custom / 1~2 buttons / optional close)
- (id)hf_curtainSheet:(HFCurtainSheet *)sheet;

/// Convenience wrappers
- (id)hf_curtainAlert:(nullable NSString *)title
              message:(NSString *)message
         confirmTitle:(NSString *)confirm
          cancelTitle:(nullable NSString *)cancel
                 tier:(HFCurtainTier)tier
              confirm:(nullable void (^)(void))onConfirm
               cancel:(nullable void (^)(void))onCancel;

- (id)hf_curtainReview;
/// Progress 0～1 or 0～100; never decreases; caps at 99.
- (void)hf_curtainReviewProgress:(CGFloat)p;
- (void)hf_curtainReviewClose;

- (id)hf_curtainPermTitle:(NSString *)title
                     body:(NSString *)body
                  confirm:(void (^)(void))onSettings
                   cancel:(nullable void (^)(void))onCancel;

/// Force-update dialog: single primary button, no close, does not auto-dismiss
- (id)hf_curtainForceUpdate:(NSString *)message storeURL:(NSString *)storeURL;

/// 19 — order / apply success sheet (PH: dialog, not page). Confirm → `onConfirm` then caller may try 45.
- (id)hf_curtainOrderSuccess:(nullable void (^)(void))onConfirm;

@end

NS_ASSUME_NONNULL_END
