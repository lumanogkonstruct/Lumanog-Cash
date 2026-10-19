#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 45 — rate-us guidance (uses 41 `HFStarRail` + 08 sheet)
@interface HFPraiseGate : NSObject

+ (instancetype)shared;

/// Cache appUserType from home / user info (1=new, 2=old).
- (void)hf_praiseRememberKind:(NSInteger)userKind;

/// Try show with cached user kind.
- (void)hf_praiseTrySubmit:(nullable void (^)(NSInteger score))onSubmit
                    cancel:(nullable void (^)(void))onCancel;

/// Try show for explicit user kind (1/2).
- (void)hf_praiseTryKind:(NSInteger)userKind
                  submit:(nullable void (^)(NSInteger score))onSubmit
                  cancel:(nullable void (^)(void))onCancel;

/// 1～3 thank-you sheet.
- (void)hf_praiseThank:(nullable void (^)(void))onConfirm;

@end

NS_ASSUME_NONNULL_END
