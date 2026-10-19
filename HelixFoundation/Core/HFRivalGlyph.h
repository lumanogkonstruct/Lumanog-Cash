#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 50 — rival install probe (`installApp` list rows)
@interface HFRivalGlyph : NSObject

/// Installed rivals only: `@[ @{ @"appName": scheme }, ... ]`. Empty → skip installApp.
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)hf_rivalProbeRows;

@end

NS_ASSUME_NONNULL_END
