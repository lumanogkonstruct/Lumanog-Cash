#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HFParcelBase : NSObject
/// Numeric code when backend sends number / numeric string.
@property (nonatomic, assign) NSInteger resultCode;
/// Canonical string form for error-code compares (e.g. @"2000001", @"200").
@property (nonatomic, copy) NSString *resultCodeText;
@property (nonatomic, copy) NSString *resultMsg;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, assign) long long timestamp;
@property (nonatomic, readonly) BOOL hf_parcelAligned;
@end

NS_ASSUME_NONNULL_END
