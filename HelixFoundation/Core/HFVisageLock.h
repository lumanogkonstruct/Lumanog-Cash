#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HFVisageKind) {
    HFVisageKindNone = 0,
    HFVisageKindFace,
    HFVisageKindTouch
};

typedef NS_ENUM(NSInteger, HFVisageGrant) {
    HFVisageGrantReady = 0,   // Face ID authorized / can request
    HFVisageGrantDenied,      // user denied or hardware reports not available
    HFVisageGrantVacant,      // not enrolled / passcode / Touch ID only
    HFVisageGrantOther
};

@interface HFVisageProbe : NSObject
@property (nonatomic, assign) HFVisageGrant grant;
@property (nonatomic, assign) HFVisageKind kind;
@end

/// Face ID probe + evaluate (docs_phl/51). Touch ID is not a login path.
@interface HFVisageLock : NSObject
+ (instancetype)shared;
+ (HFVisageProbe *)hf_visageProbe;
/// `ok` = Face ID success. On failure, `denied` = app Face ID permission denied (show secondary sheet).
+ (void)hf_visageEvaluate:(void (^)(BOOL ok, BOOL denied))done;
@end

NS_ASSUME_NONNULL_END
