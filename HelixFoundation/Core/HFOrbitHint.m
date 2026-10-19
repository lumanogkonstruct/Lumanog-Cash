#import "HFOrbitHint.h"
#import "HFLatticeKit.h"
#import <SDWebImage/SDAnimatedImage.h>
#import <SDWebImage/SDAnimatedImageView.h>

@interface HFOrbitHint () <UIPopoverPresentationControllerDelegate>
@property (nonatomic, weak) UIView *pulseView;
@property (nonatomic, strong, nullable) UIWindow *spinWin;
@property (nonatomic, assign) NSInteger spinDepth;
@property (nonatomic, weak) UIViewController *bubbleVC;
@end

@implementation HFOrbitHint

+ (instancetype)shared {
    static HFOrbitHint *ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [HFOrbitHint new];
    });
    return ins;
}

- (void)hf_onMain:(dispatch_block_t)block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (nullable UIWindowScene *)hf_activeScene {
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)s;
        }
    }
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]]) return (UIWindowScene *)s;
    }
    return nil;
}

- (nullable UIWindow *)hf_frontWindow {
    UIWindowScene *scene = [self hf_activeScene];
    if (!scene) return nil;
    UIWindow *key = nil;
    for (UIWindow *w in scene.windows) {
        if (w == self.spinWin) continue;
        if (w.bounds.size.width < 100 || w.bounds.size.height < 100) continue;
        if (!w.rootViewController) continue;
        if (w.isKeyWindow) {
            key = w;
            break;
        }
        if (!key) key = w;
    }
    return key;
}

/// 01 / 08 — Bundle `loading.gif`; fallback ActivityIndicator.
- (UIView *)hf_orbitSpinGlyph {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"loading" ofType:@"gif"];
    if (path.length) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        SDAnimatedImage *anim = data.length ? [SDAnimatedImage imageWithData:data] : nil;
        if (anim) {
            SDAnimatedImageView *iv = [[SDAnimatedImageView alloc] initWithImage:anim];
            iv.contentMode = UIViewContentModeScaleAspectFit;
            return iv;
        }
    }
    UIActivityIndicatorView *ind = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    ind.color = UIColor.whiteColor;
    [ind startAnimating];
    return ind;
}

- (void)hf_orbitPulse:(NSString *)text {
    [self hf_orbitPulse:text duration:2.0];
}

- (void)hf_orbitPulse:(NSString *)text duration:(NSTimeInterval)seconds {
    [self hf_onMain:^{
        NSString *t = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (t.length == 0) return;
        UIWindow *win = [self hf_frontWindow];
        if (!win) return;
        [self.pulseView removeFromSuperview];
        UILabel *lab = [UILabel new];
        lab.text = t;
        lab.textColor = UIColor.whiteColor;
        lab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
        lab.numberOfLines = 0;
        lab.textAlignment = NSTextAlignmentCenter;
        UIView *box = [UIView new];
        box.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
        box.layer.cornerRadius = 8;
        box.alpha = 0;
        [box addSubview:lab];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [lab.topAnchor constraintEqualToAnchor:box.topAnchor constant:12],
            [lab.bottomAnchor constraintEqualToAnchor:box.bottomAnchor constant:-12],
            [lab.leadingAnchor constraintEqualToAnchor:box.leadingAnchor constant:16],
            [lab.trailingAnchor constraintEqualToAnchor:box.trailingAnchor constant:-16],
            [lab.widthAnchor constraintLessThanOrEqualToConstant:260]
        ]];
        [win addSubview:box];
        box.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [box.centerXAnchor constraintEqualToAnchor:win.centerXAnchor],
            [box.centerYAnchor constraintEqualToAnchor:win.centerYAnchor],
            [box.leadingAnchor constraintGreaterThanOrEqualToAnchor:win.leadingAnchor constant:40],
            [box.trailingAnchor constraintLessThanOrEqualToAnchor:win.trailingAnchor constant:-40]
        ]];
        self.pulseView = box;
        [UIView animateWithDuration:0.25 animations:^{ box.alpha = 1; }];
        NSTimeInterval d = seconds > 0 ? seconds : 2.0;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakSelf.pulseView != box) return;
            [UIView animateWithDuration:0.25 animations:^{ box.alpha = 0; } completion:^(__unused BOOL f) {
                [box removeFromSuperview];
            }];
        });
    }];
}

- (UIView *)hf_orbitBuildMask:(NSString *)text frame:(CGRect)frame {
    // Loading：仅遮罩 + 图标，不展示文字（text 参数忽略）
    (void)text;
    UIView *mask = [[UIView alloc] initWithFrame:frame];
    mask.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    mask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mask.userInteractionEnabled = YES;
    mask.tag = 91001;

    UIView *glyph = [self hf_orbitSpinGlyph];
    [mask addSubview:glyph];
    glyph.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [glyph.centerXAnchor constraintEqualToAnchor:mask.centerXAnchor],
        [glyph.centerYAnchor constraintEqualToAnchor:mask.centerYAnchor],
        [glyph.widthAnchor constraintEqualToConstant:72],
        [glyph.heightAnchor constraintEqualToConstant:72],
    ]];
    return mask;
}

- (void)hf_orbitTearSpinWin {
    if (!self.spinWin) return;
    UIWindow *dying = self.spinWin;
    self.spinWin = nil;
    dying.hidden = YES;
    dying.rootViewController = nil;
    UIWindow *front = [self hf_frontWindow];
    if (front) [front makeKeyWindow];
}

/// Ensure Loading UI is visible (Mid Window preferred; fallback to key window subview).
- (void)hf_orbitEnsureSpinUI:(NSString *)text {
    if (self.spinWin && !self.spinWin.hidden) return;
    UIWindow *fallback = [self hf_frontWindow];
    [[fallback viewWithTag:91001] removeFromSuperview];

    UIWindowScene *scene = [self hf_activeScene];
    if (scene) {
        UIWindow *w = [[UIWindow alloc] initWithWindowScene:scene];
        w.windowLevel = UIWindowLevelAlert - 2; // Mid — below High (version update)

        w.backgroundColor = UIColor.clearColor;
        UIViewController *vc = [UIViewController new];
        UIView *mask = [self hf_orbitBuildMask:text frame:UIScreen.mainScreen.bounds];
        [vc.view addSubview:mask];
        w.rootViewController = vc;
        w.hidden = NO;
        [w makeKeyAndVisible];
        self.spinWin = w;
        return;
    }
    if (!fallback) return;
    UIView *mask = [self hf_orbitBuildMask:text frame:fallback.bounds];
    [fallback addSubview:mask];
}

- (void)hf_orbitSpin:(NSString *)text {
    [self hf_onMain:^{
        self.spinDepth += 1;
        [self hf_orbitEnsureSpinUI:text];
    }];
}

- (void)hf_orbitHaltSpin {
    [self hf_onMain:^{
        if (self.spinDepth > 0) self.spinDepth -= 1;
        if (self.spinDepth > 0) return;
        self.spinDepth = 0;
        if (self.spinWin) {
            [self hf_orbitTearSpinWin];
        } else {
            UIWindow *win = [self hf_frontWindow];
            [[win viewWithTag:91001] removeFromSuperview];
        }
    }];
}

- (void)hf_orbitForceHaltSpin {
    [self hf_onMain:^{
        self.spinDepth = 0;
        if (self.spinWin) {
            [self hf_orbitTearSpinWin];
        }
        UIWindow *win = [self hf_frontWindow];
        [[win viewWithTag:91001] removeFromSuperview];
    }];
}

- (void)hf_orbitBubble:(NSString *)text anchor:(UIView *)sourceView host:(UIViewController *)presenter {
    [self hf_orbitBubble:text anchor:sourceView host:presenter duration:3.0];
}

- (void)hf_orbitBubble:(NSString *)text anchor:(UIView *)sourceView host:(UIViewController *)presenter duration:(NSTimeInterval)seconds {
    [self hf_onMain:^{
        NSString *t = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (t.length == 0 || !sourceView || !presenter) return;
        if (self.bubbleVC) {
            [self.bubbleVC dismissViewControllerAnimated:NO completion:nil];
            self.bubbleVC = nil;
        }
        UIViewController *vc = [UIViewController new];
        vc.modalPresentationStyle = UIModalPresentationPopover;
        vc.preferredContentSize = CGSizeMake(220, 80);
        UILabel *lab = [UILabel new];
        lab.text = t;
        lab.textColor = UIColor.whiteColor;
        lab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
        lab.numberOfLines = 0;
        lab.textAlignment = NSTextAlignmentLeft;
        lab.backgroundColor = UIColor.clearColor;
        [vc.view addSubview:lab];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [lab.topAnchor constraintEqualToAnchor:vc.view.topAnchor constant:8],
            [lab.bottomAnchor constraintEqualToAnchor:vc.view.bottomAnchor constant:-8],
            [lab.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor constant:10],
            [lab.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor constant:-10]
        ]];
        UIPopoverPresentationController *pop = vc.popoverPresentationController;
        pop.sourceView = sourceView;
        pop.sourceRect = CGRectMake(sourceView.bounds.size.width * 0.5, sourceView.bounds.size.height, 1, 1);
        pop.permittedArrowDirections = UIPopoverArrowDirectionUp;
        pop.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
        pop.delegate = self;
        self.bubbleVC = vc;
        [presenter presentViewController:vc animated:YES completion:nil];
        NSTimeInterval d = seconds > 0 ? seconds : 3.0;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakSelf.bubbleVC == vc) {
                [vc dismissViewControllerAnimated:YES completion:^{
                    if (weakSelf.bubbleVC == vc) weakSelf.bubbleVC = nil;
                }];
            }
        });
    }];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
