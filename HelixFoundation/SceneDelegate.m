#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "HFQuillVault.h"
#import "HFDockBar.h"
#import "HFPortalSeal.h"
#import "HFNexusPipe.h"
#import "HFTraceMark.h"
#import "HFVaultSeal.h"

@interface SceneDelegate ()
@property (nonatomic, assign) BOOL hf_pipeReady;
@property (nonatomic, assign) BOOL hf_attTriggered;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    UIWindowScene *ws = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:ws];
    self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;

    NSString *token = [HFQuillVault hf_quillGate];
    if (token.length > 0) {
        self.window.rootViewController = [HFDockBar hf_dockAssemble];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[HFPortalSeal new]];
        nav.navigationBarHidden = YES;
        self.window.rootViewController = nav;
    }
    [self.window makeKeyAndVisible];

    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipeBoot:^(BOOL ready) {
        weakSelf.hf_pipeReady = ready;
        if (!ready) {
            NSLog(@"[SceneDelegate] network boot failed");
            return;
        }
        [[HFTraceMark shared] hf_trace:HFTraceCodeLaunch];
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        if (![ud boolForKey:[HFVaultSeal kRhoFirstFlag]]) {
            [ud setBool:YES forKey:[HFVaultSeal kRhoFirstFlag]];
            [ud synchronize];
            [[HFTraceMark shared] hf_trace:HFTraceCodeFirstOpen];
        }
        AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
        if ([app isKindOfClass:[AppDelegate class]]) {
            [app hf_appFlushIdfaTrace];
            [weakSelf hf_sceneTriggerATT];
        }
    }];
}

- (void)hf_sceneTriggerATT {
    if (!self.hf_pipeReady) return;
    // Allow retry via becomeActive until AppDelegate marks asked.
    AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
    if (![app isKindOfClass:[AppDelegate class]]) return;
    self.hf_attTriggered = YES;
    NSLog(@"[SceneDelegate] trigger ATT (pipeReady=1)");
    [app hf_appRequestATTIfNeeded];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
    if (self.hf_pipeReady) {
        // Retry ATT if deferred (must be active for system dialog).
        [self hf_sceneTriggerATT];
        if ([app isKindOfClass:[AppDelegate class]]) {
            [app hf_appFlushIdfaTrace];
        }
    }
}

- (void)hf_sceneSwapRoot:(UIViewController *)vc {
    if (!self.window) return;
    UIView *snap = [self.window snapshotViewAfterScreenUpdates:YES];
    if (snap) [vc.view addSubview:snap];
    self.window.rootViewController = vc;
    [UIView animateWithDuration:0.25 animations:^{
        snap.alpha = 0;
    } completion:^(__unused BOOL finished) {
        [snap removeFromSuperview];
    }];
}

- (void)hf_sceneShowMain {
    [self hf_sceneSwapRoot:[HFDockBar hf_dockAssemble]];
}

- (void)hf_sceneShowGate {
    [HFQuillVault hf_quillErase];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[HFPortalSeal new]];
    nav.navigationBarHidden = YES;
    [self hf_sceneSwapRoot:nav];
}

@end
