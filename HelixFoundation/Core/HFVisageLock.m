#import "HFVisageLock.h"
#import <LocalAuthentication/LocalAuthentication.h>

@implementation HFVisageProbe
@end

@implementation HFVisageLock

+ (instancetype)shared {
    static HFVisageLock *ins;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        ins = [HFVisageLock new];
    });
    return ins;
}

+ (LAContext *)hf_ctx {
    LAContext *c = [LAContext new];
    c.localizedFallbackTitle = @"";
    return c;
}

+ (HFVisageProbe *)hf_visageProbe {
    HFVisageProbe *out = [HFVisageProbe new];
    LAContext *ctx = [self hf_ctx];
    NSError *err = nil;
    // biometryType is only reliable after canEvaluatePolicy:
    BOOL ok = [ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&err];
    LABiometryType bio = ctx.biometryType;
    if (bio == LABiometryTypeFaceID) {
        out.kind = HFVisageKindFace;
    } else if (bio == LABiometryTypeTouchID) {
        out.kind = HFVisageKindTouch;
    } else {
        out.kind = HFVisageKindNone;
    }

    if (ok) {
        if (bio == LABiometryTypeFaceID) {
            out.grant = HFVisageGrantReady;
        } else {
            // Touch ID / none — Face ID login path not available
            out.grant = HFVisageGrantVacant;
        }
        return out;
    }

    NSInteger code = err.code;
    if (code == LAErrorBiometryLockout) {
        out.grant = HFVisageGrantOther;
        return out;
    }
    if (code == LAErrorBiometryNotEnrolled || code == LAErrorPasscodeNotSet) {
        out.grant = HFVisageGrantVacant;
        return out;
    }
    // User denied Face ID for this app (Settings toggle / Don't Allow) → -6 + Face ID type
    if (bio == LABiometryTypeFaceID && code == LAErrorBiometryNotAvailable) {
        out.grant = HFVisageGrantDenied;
        return out;
    }
    if (code == LAErrorBiometryNotAvailable) {
        // No Face ID hardware
        out.grant = HFVisageGrantVacant;
        return out;
    }
    // Face ID present but cannot evaluate (treat as denied so secondary sheet can show)
    if (bio == LABiometryTypeFaceID) {
        out.grant = HFVisageGrantDenied;
        return out;
    }
    out.grant = HFVisageGrantOther;
    return out;
}

+ (void)hf_visageEvaluate:(void (^)(BOOL ok, BOOL denied))done {
    LAContext *ctx = [self hf_ctx];
    NSError *err = nil;
    if (![ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&err]) {
        BOOL denied = ([self hf_visageProbe].grant == HFVisageGrantDenied);
        if (done) done(NO, denied);
        return;
    }
    [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
        localizedReason:@"Sign in with Face ID"
                  reply:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                if (done) done(YES, NO);
                return;
            }
            // Don't Allow on system Face ID permission → -6; cancel / mismatch → OTP
            BOOL denied = NO;
            if (error.code == LAErrorBiometryNotAvailable && ctx.biometryType == LABiometryTypeFaceID) {
                denied = YES;
            } else if ([self hf_visageProbe].grant == HFVisageGrantDenied) {
                denied = YES;
            }
            if (done) done(NO, denied);
        });
    }];
}

@end
