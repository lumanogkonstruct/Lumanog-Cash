#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Module 04 — device info harvest + UA
@interface HFProbeAtlas : NSObject

/// Returns dictionary with exact 32 keys (empty → @"null").
+ (NSDictionary<NSString *, id> *)hf_probeHarvest;

/// HTTP User-Agent: APPID/APPVersion (Apple; Mobile|Tablet|pc; model; iOS x)
+ (NSString *)hf_probeUA;

@end

NS_ASSUME_NONNULL_END
