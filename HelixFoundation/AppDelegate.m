#import "AppDelegate.h"
#import "HFVaultSeal.h"
#import "HFTraceMark.h"
#import "HFFloatOrb.h"
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>
#import <AdjustSdk/Adjust.h>
#import <AdjustSdk/ADJConfig.h>

NSNotificationName const HFAdjustDidInitNotification = @"HFAdjustDidInitNotification";

@interface AppDelegate ()
@property (nonatomic, assign) BOOL hf_attAsked;
@property (nonatomic, assign) BOOL hf_adjustInited;
@property (nonatomic, strong, nullable) NSNumber *hf_pendingIdfaCode; // 17 or 18
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self hf_appWireKeyboard];
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[HFVaultSeal kUpsilonSessionFlag]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[HFFloatOrb shared] hf_orbShow];
    });
    return YES;
}

- (void)hf_appWireKeyboard {
    IQKeyboardManager *m = [IQKeyboardManager sharedManager];
    m.enable = YES;
    m.shouldResignOnTouchOutside = YES;
    m.enableAutoToolbar = YES;
    m.keyboardDistanceFromTextField = 20.0;
    m.toolbarDoneBarButtonItemText = @"Done";
}

#pragma mark - ATT / Adjust / IDFA

- (void)hf_appRequestATTIfNeeded {
    if (self.hf_attAsked) {
        NSLog(@"[AppDelegate] ATT already handled — flush only");
        [self hf_appFlushIdfaTrace];
        return;
    }
    void (^run)(void) = ^{
        UIApplicationState stApp = UIApplication.sharedApplication.applicationState;
        NSLog(@"[AppDelegate] ATT enter appState=%ld", (long)stApp);
        if (stApp != UIApplicationStateActive) {
            NSLog(@"[AppDelegate] ATT defer — app not active");
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hf_appOnBecomeActiveForATT) name:UIApplicationDidBecomeActiveNotification object:nil];
            return;
        }
        // Delay so key window / login UI settle (ATT needs active foreground).
        NSLog(@"[AppDelegate] ATT schedule request in 0.8s");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.hf_attAsked) {
                NSLog(@"[AppDelegate] ATT skip — already asked during delay");
                return;
            }
            if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
                NSLog(@"[AppDelegate] ATT defer after delay — not active");
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hf_appOnBecomeActiveForATT) name:UIApplicationDidBecomeActiveNotification object:nil];
                return;
            }
            ATTrackingManagerAuthorizationStatus st = ATTrackingManager.trackingAuthorizationStatus;
            // 0=notDetermined 1=restricted 2=denied 3=authorized
            NSLog(@"[AppDelegate] ATT status before request=%ld", (long)st);
            self.hf_attAsked = YES;
            if (st == ATTrackingManagerAuthorizationStatusNotDetermined) {
                NSLog(@"[AppDelegate] ATT present system dialog");
                [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                    NSLog(@"[AppDelegate] ATT user result=%ld", (long)status);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hf_appHandleATT:status];
                    });
                }];
            } else {
                // Already decided / Tracking master switch off → no dialog.
                NSLog(@"[AppDelegate] ATT skip dialog (status=%ld). Settings→Privacy→Tracking if needed.", (long)st);
                [self hf_appHandleATT:st];
            }
        });
    };
    if ([NSThread isMainThread]) run();
    else dispatch_async(dispatch_get_main_queue(), run);
}

- (void)hf_appOnBecomeActiveForATT {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [self hf_appRequestATTIfNeeded];
}

- (void)hf_appHandleATT:(ATTrackingManagerAuthorizationStatus)status {
    BOOL ok = (status == ATTrackingManagerAuthorizationStatusAuthorized);
    self.hf_pendingIdfaCode = ok ? @(HFTraceCodeIdfaOK) : @(HFTraceCodeIdfaNo);
    [self hf_appInitAdjustOnce];
    [self hf_appFlushIdfaTrace];
}

- (BOOL)hf_adjustReady {
    return self.hf_adjustInited;
}

- (void)hf_appInitAdjustOnce {
    if (self.hf_adjustInited) return;
    NSString *token = [HFVaultSeal kGammaToken];
    if (token.length == 0) return;
    ADJConfig *cfg = [[ADJConfig alloc] initWithAppToken:token environment:ADJEnvironmentProduction];
    [Adjust initSdk:cfg];
    self.hf_adjustInited = YES;
    NSLog(@"[AppDelegate] Adjust initSdk done");
    [[NSNotificationCenter defaultCenter] postNotificationName:HFAdjustDidInitNotification object:nil];
}

- (void)hf_appFlushIdfaTrace {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if ([ud boolForKey:[HFVaultSeal kOmegaIdfaFlag]]) {
        self.hf_pendingIdfaCode = nil;
        return;
    }
    if (!self.hf_pendingIdfaCode) return;
    HFTraceCode code = (HFTraceCode)self.hf_pendingIdfaCode.integerValue;
    [[HFTraceMark shared] hf_trace:code];
    [ud setBool:YES forKey:[HFVaultSeal kOmegaIdfaFlag]];
    [ud synchronize];
    self.hf_pendingIdfaCode = nil;
    NSLog(@"[AppDelegate] IDFA bury code=%ld", (long)code);
}

#pragma mark - Scene

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

@end
