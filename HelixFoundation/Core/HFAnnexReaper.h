#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 37/38 — annex harvest for H5 `uploadData` (device → contact → ready)
@interface HFAnnexReaper : NSObject

+ (instancetype)shared;

/// Only-data pipeline. `rosterAuthFail` = contacts force interrupt (may pop home on product-apply).
- (void)hf_annexIgnite:(NSString *)orderId
                   host:(UIView *)host
                   done:(void (^)(BOOL ok, BOOL rosterAuthFail))done;

@end

NS_ASSUME_NONNULL_END
