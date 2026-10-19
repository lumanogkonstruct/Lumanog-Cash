#import "HFCanvasRoot.h"

NS_ASSUME_NONNULL_BEGIN

/// 10 / 10.1 — Web container + H5 JSBridge (`iosHandler` / `mobileUserdata`)
@interface HFPaneBrowse : HFCanvasRoot

- (instancetype)initWithURLString:(NSString *)url title:(nullable NSString *)title;

- (instancetype)initH5WithURLString:(NSString *)url
                              title:(nullable NSString *)title
                             extras:(nullable NSDictionary *)extras;

@end

NS_ASSUME_NONNULL_END
