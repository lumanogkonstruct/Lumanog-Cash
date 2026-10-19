#import "HFCurtainBox.h"
#import "HFLatticeKit.h"
#import "HFOrbitHint.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDAnimatedImage.h>
#import <SDWebImage/SDAnimatedImageView.h>

@implementation HFCurtainSheet
- (instancetype)init {
    self = [super init];
    if (self) {
        _showClose = NO;
        _tapOutsideToClose = NO;
        _autoCloseOnAction = YES;
        _tier = HFCurtainTierMid;
    }
    return self;
}
@end

@interface HFCurtainBox ()
@property (nonatomic, strong) NSMutableArray<UIWindow *> *wins;
@property (nonatomic, strong) UIWindow *reviewWin;
@property (nonatomic, strong, nullable) id forceToken;
@property (nonatomic, weak) UILabel *hf_reviewPctLab;
@property (nonatomic, assign) CGFloat hf_reviewPct;
@property (nonatomic, strong, nullable) dispatch_source_t hf_reviewTimer;
@end

@implementation HFCurtainBox

+ (instancetype)shared {
    static HFCurtainBox *ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [HFCurtainBox new];
        ins.wins = [NSMutableArray array];
    });
    return ins;
}

- (UIWindowScene *)hf_scene {
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)s;
        }
    }
    return (UIWindowScene *)UIApplication.sharedApplication.connectedScenes.anyObject;
}

- (UIWindowLevel)hf_level:(HFCurtainTier)tier {

    // UIWindowLevelAlert(2000) > StatusBar(1000) — High must NOT use StatusBar.
    switch (tier) {
        case HFCurtainTierVeryLow: return UIWindowLevelNormal + 1;
        case HFCurtainTierLow:     return UIWindowLevelAlert - 3;
        case HFCurtainTierMid:     return UIWindowLevelAlert - 2;
        case HFCurtainTierHigh:    return UIWindowLevelAlert - 1;
        default:                   return UIWindowLevelAlert - 2;
    }
}

- (UIWindow *)hf_makeWin:(HFCurtainTier)tier {
    UIWindowScene *scene = [self hf_scene];
    UIWindow *w = scene ? [[UIWindow alloc] initWithWindowScene:scene] : [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    w.windowLevel = [self hf_level:tier];
    w.backgroundColor = UIColor.clearColor;
    w.hidden = NO;
    [self.wins addObject:w];
    return w;
}

- (UIButton *)hf_pill:(NSString *)title primary:(BOOL)primary {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightRegular];
    b.layer.cornerRadius = 22;
    b.clipsToBounds = YES;
    UIColor *ink = [UIColor hf_prismInk];
    if (primary) {
        b.backgroundColor = [UIColor hf_prismTheme]; // #EFA37A
    } else {
        b.backgroundColor = [UIColor hf_prismHex:@"#F5EDE2"];
    }
    [b setTitleColor:ink forState:UIControlStateNormal];
    return b;
}

#pragma mark - Mask loading

- (UIView *)hf_curtainSpinGlyph {
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

- (id)hf_curtainMask:(NSString *)text tier:(HFCurtainTier)tier {
    UIWindow *w = [self hf_makeWin:tier];
    UIViewController *vc = [UIViewController new];
    // 08 §1: full-screen 0.7 + gif + text
    vc.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 16;
    [vc.view addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(vc.view);
        make.leading.greaterThanOrEqualTo(vc.view).offset(36);
        make.trailing.lessThanOrEqualTo(vc.view).offset(-36);
    }];

    UIView *spinHost = [self hf_curtainSpinGlyph];
    [stack addArrangedSubview:spinHost];
    [spinHost mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(72);
    }];

    NSString *caption = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (caption.length == 0) {
        static NSArray<NSString *> *tips;
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            tips = @[
                @"Get instant disbursement in just a few simple steps.",
                @"Personalized financial solutions",
                @"Industry-leading security measures",
                @"No complicated procedures required",
            ];
        });
        caption = tips[arc4random_uniform((uint32_t)tips.count)];
    }
    UILabel *lab = [UILabel new];
    lab.text = caption;
    lab.textColor = UIColor.whiteColor;
    lab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    lab.textAlignment = NSTextAlignmentCenter;
    lab.numberOfLines = 0;
    [stack addArrangedSubview:lab];

    w.rootViewController = vc;
    [w makeKeyAndVisible];
    return w;
}

- (void)hf_curtainDismiss:(id)token {
    if (![token isKindOfClass:[UIWindow class]]) return;
    UIWindow *w = (UIWindow *)token;
    if (self.reviewWin == w) {
        [self hf_curtainReviewStopTick];
        self.hf_reviewPctLab = nil;
        self.hf_reviewPct = 0;
        self.reviewWin = nil;
    }
    w.hidden = YES;
    w.rootViewController = nil;
    [self.wins removeObject:w];
    if (self.forceToken == w) {
        self.forceToken = nil;
    }
}

#pragma mark - Design sheet

- (id)hf_curtainSheet:(HFCurtainSheet *)sheet {
    if (!sheet) return nil;
    UIWindow *w = [self hf_makeWin:sheet.tier];
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];

    UIView *card = [UIView new];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 18;
    card.clipsToBounds = YES;
    [vc.view addSubview:card];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(vc.view);
        make.leading.equalTo(vc.view).offset(36);
        make.trailing.equalTo(vc.view).offset(-36);
    }];

    // Close — top-left, default hidden
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *closeImg = [[UIImage imageNamed:@"two_icon_del"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [closeBtn setImage:closeImg forState:UIControlStateNormal];
    closeBtn.hidden = !sheet.showClose;
    [card addSubview:closeBtn];
    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(12);
        make.leading.equalTo(card).offset(12);
        make.width.height.mas_equalTo(28);
    }];

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 14;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(sheet.showClose ? 40 : 28);
        make.leading.equalTo(card).offset(20);
        make.trailing.equalTo(card).offset(-20);
    }];

    BOOL hasTitle = sheet.titleText.length > 0;
    if (hasTitle) {
        UILabel *title = [UILabel new];
        title.text = sheet.titleText;
        title.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightRegular];
        title.textColor = [UIColor hf_prismInk];
        title.textAlignment = NSTextAlignmentCenter;
        title.numberOfLines = 0;
        [stack addArrangedSubview:title];
    }

    if (sheet.bodyText.length > 0) {
        UILabel *body = [UILabel new];
        body.text = sheet.bodyText;
        body.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
        body.textColor = [UIColor hf_prismInk];
        body.textAlignment = NSTextAlignmentCenter;
        body.numberOfLines = 0;
        [stack addArrangedSubview:body];
        if (hasTitle) {
            [stack setCustomSpacing:10 afterView:stack.arrangedSubviews.firstObject];
        }
    }

    if (sheet.extraView) {
        [stack addArrangedSubview:sheet.extraView];
    }

    // Buttons
    UIView *btnRow = [UIView new];
    [card addSubview:btnRow];
    [btnRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(stack.mas_bottom).offset(22);
        make.leading.equalTo(card).offset(20);
        make.trailing.equalTo(card).offset(-20);
        make.bottom.equalTo(card).offset(-24);
        make.height.mas_equalTo(44);
    }];

    __weak typeof(self) weakSelf = self;
    BOOL hasLeft = sheet.leftTitle.length > 0;
    NSString *right = sheet.rightTitle.length ? sheet.rightTitle : @"Confirm";

    UIButton *rightBtn = [self hf_pill:right primary:YES];
    [btnRow addSubview:rightBtn];
    [rightBtn addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
        if (sheet.autoCloseOnAction) [weakSelf hf_curtainDismiss:w];
        if (sheet.onRight) sheet.onRight();
    }] forControlEvents:UIControlEventTouchUpInside];

    if (hasLeft) {
        UIButton *leftBtn = [self hf_pill:sheet.leftTitle primary:NO];
        [btnRow addSubview:leftBtn];
        [leftBtn addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
            if (sheet.autoCloseOnAction) [weakSelf hf_curtainDismiss:w];
            if (sheet.onLeft) sheet.onLeft();
        }] forControlEvents:UIControlEventTouchUpInside];
        [leftBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.top.bottom.equalTo(btnRow);
            make.trailing.equalTo(btnRow.mas_centerX).offset(-6);
        }];
        [rightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.top.bottom.equalTo(btnRow);
            make.leading.equalTo(btnRow.mas_centerX).offset(6);
        }];
    } else {
        [rightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(btnRow);
        }];
    }

    [closeBtn addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
        if (sheet.requireDoubleClose && !sheet.hf_closeArmed) {
            sheet.hf_closeArmed = YES;
            return;
        }
        [weakSelf hf_curtainDismiss:w];
        if (sheet.onClose) sheet.onClose();
    }] forControlEvents:UIControlEventTouchUpInside];

    if (sheet.tapOutsideToClose) {
        UIButton *dim = [UIButton buttonWithType:UIButtonTypeCustom];
        dim.backgroundColor = UIColor.clearColor;
        [vc.view insertSubview:dim belowSubview:card];
        [dim mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(vc.view); }];
        [dim addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
            [weakSelf hf_curtainDismiss:w];
            if (sheet.onClose) sheet.onClose();
        }] forControlEvents:UIControlEventTouchUpInside];
    }

    w.rootViewController = vc;
    [w makeKeyAndVisible];
    return w;
}

- (id)hf_curtainAlert:(NSString *)title
              message:(NSString *)message
         confirmTitle:(NSString *)confirm
          cancelTitle:(NSString *)cancel
                 tier:(HFCurtainTier)tier
              confirm:(void (^)(void))onConfirm
               cancel:(void (^)(void))onCancel {
    HFCurtainSheet *s = [HFCurtainSheet new];
    s.titleText = title;
    s.bodyText = message;
    s.tier = tier;
    // Design: left = secondary Cancel (beige), right = primary Confirm (orange)
    if (cancel.length) {
        s.leftTitle = cancel;
        s.rightTitle = confirm.length ? confirm : @"Confirm";
        s.onLeft = onCancel;
        s.onRight = onConfirm;
    } else {
        s.rightTitle = confirm.length ? confirm : @"Confirm";
        s.onRight = onConfirm;
    }
    return [self hf_curtainSheet:s];
}

- (id)hf_curtainForceUpdate:(NSString *)message storeURL:(NSString *)storeURL {
    if (self.forceToken) return self.forceToken;
    (void)message; // body text fixed by design
    HFCurtainSheet *s = [HFCurtainSheet new];
    s.titleText = @"Upgrade";
    s.bodyText = @"New version found";
    s.rightTitle = @"Confirm";
    s.showClose = NO;
    s.tapOutsideToClose = NO;
    s.autoCloseOnAction = NO; // stay until user leaves app via Store
    s.tier = HFCurtainTierHigh;
    __weak typeof(self) weakSelf = self;
    s.onRight = ^{
        NSString *u = storeURL;
        if (u.length == 0) return;
        NSURL *url = [NSURL URLWithString:u];
        if (!url) return;
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        (void)weakSelf;
    };
    id token = [self hf_curtainSheet:s];
    self.forceToken = token;
    return token;
}

#pragma mark - Review / Permission

- (void)hf_curtainReviewStopTick {
    if (self.hf_reviewTimer) {
        dispatch_source_cancel(self.hf_reviewTimer);
        self.hf_reviewTimer = nil;
    }
}

- (void)hf_curtainReviewApplyPct:(CGFloat)pct {
    CGFloat next = MIN(99.0, MAX(self.hf_reviewPct, pct));
    if (next < self.hf_reviewPct) return; // 08 §3.2: never go back
    self.hf_reviewPct = next;
    NSInteger shown = (NSInteger)floor(self.hf_reviewPct + 1e-6);
    self.hf_reviewPctLab.text = [NSString stringWithFormat:@"%ld%%", (long)shown];
    if (self.hf_reviewPct >= 99.0 - 1e-6) {
        [self hf_curtainReviewStopTick];
    }
}

- (void)hf_curtainReviewStartTick {
    [self hf_curtainReviewStopTick];
    self.hf_reviewPct = 0;
    [self hf_curtainReviewApplyPct:0];

    dispatch_queue_t q = dispatch_get_main_queue();
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
    self.hf_reviewTimer = timer;
    __weak typeof(self) weakSelf = self;
    void (^arm)(void) = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.hf_reviewTimer) return;
        uint64_t ms = 200 + arc4random_uniform(1801); // 200～2000 ms
        dispatch_source_set_timer(self.hf_reviewTimer,
                                  dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ms * NSEC_PER_MSEC)),
                                  DISPATCH_TIME_FOREVER,
                                  (int64_t)(50 * NSEC_PER_MSEC));
    };
    dispatch_source_set_event_handler(timer, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.hf_reviewPct >= 99.0 - 1e-6) {
            [self hf_curtainReviewStopTick];
            return;
        }
        // 0.01%～10%
        CGFloat step = 0.01 + ((CGFloat)arc4random_uniform(1000) / 100.0); // 0.01～10.00
        [self hf_curtainReviewApplyPct:self.hf_reviewPct + step];
        if (self.hf_reviewPct < 99.0 - 1e-6) arm();
    });
    dispatch_resume(timer);
    arm();
}

- (id)hf_curtainReview {
    if (self.reviewWin) return self.reviewWin;
    // Kill Loading completely — HaltSpin alone can leave a 0.7 mask under this review dim.
    [[HFOrbitHint shared] hf_orbitForceHaltSpin];

    UIWindow *w = [self hf_makeWin:HFCurtainTierHigh];
    if (w.windowScene) {
        w.frame = w.windowScene.coordinateSpace.bounds;
    } else {
        w.frame = UIScreen.mainScreen.bounds;
    }
    // Single dim only on vc (window stays clear).
    w.backgroundColor = UIColor.clearColor;

    UIViewController *vc = [UIViewController new];
    // docs_phl/08 §3 — single full-screen dim 0.7 (not stacked with Loading / window tint).
    vc.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 12;
    [vc.view addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(vc.view);
        make.leading.equalTo(vc.view).offset(28);
        make.trailing.equalTo(vc.view).offset(-28);
    }];

    UILabel *pct = [UILabel new];
    pct.text = @"0%";
    pct.font = [UIFont hf_latticeGlyph:48 mass:UIFontWeightMedium];
    pct.textColor = UIColor.whiteColor;
    pct.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:pct];
    self.hf_reviewPctLab = pct;
    [stack setCustomSpacing:6 afterView:pct];

    UILabel *title = [UILabel new];
    title.text = @"Under review";
    title.font = [UIFont hf_latticeGlyph:22 mass:UIFontWeightMedium];
    title.textColor = [UIColor hf_prismTheme];
    title.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:title];
    [stack setCustomSpacing:14 afterView:title];

    UILabel *mainTip = [UILabel new];
    // 08 §3.1 fixed copy
    mainTip.text = @"Please wait a moment~ We're updating your credit score, it will be done in around 15 seconds!";
    mainTip.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    mainTip.textColor = UIColor.whiteColor;
    mainTip.textAlignment = NSTextAlignmentCenter;
    mainTip.numberOfLines = 0;
    [stack addArrangedSubview:mainTip];
    [stack setCustomSpacing:22 afterView:mainTip];

    UIImageView *banner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"banner"]];
    banner.contentMode = UIViewContentModeScaleAspectFit;
    banner.clipsToBounds = YES;
    [stack addArrangedSubview:banner];
    // banner @2x 670×188 → ~335×94 pt; keep aspect, full content width
    [banner mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(stack);
        make.height.equalTo(banner.mas_width).multipliedBy(188.0 / 670.0);
    }];
    [stack setCustomSpacing:22 afterView:banner];

    UILabel *foot = [UILabel new];
    foot.text = @"Just one more step before your loan is credited, please don't leave this page.";
    foot.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    foot.textColor = UIColor.whiteColor;
    foot.textAlignment = NSTextAlignmentCenter;
    foot.numberOfLines = 0;
    [stack addArrangedSubview:foot];

    w.rootViewController = vc;
    [w makeKeyAndVisible];
    self.reviewWin = w;
    [self hf_curtainReviewStartTick];
    return w;
}

- (void)hf_curtainReviewProgress:(CGFloat)p {
    if (!self.reviewWin) return;
    // Accept 0～1 or 0～100.
    CGFloat pct = p;
    if (pct <= 1.0 + 1e-6) pct *= 100.0;
    [self hf_curtainReviewApplyPct:pct];
}

- (void)hf_curtainReviewClose {
    [self hf_curtainReviewStopTick];
    if (self.reviewWin) [self hf_curtainDismiss:self.reviewWin];
}

- (id)hf_curtainPermTitle:(NSString *)title body:(NSString *)body confirm:(void (^)(void))onSettings cancel:(void (^)(void))onCancel {
    [[HFOrbitHint shared] hf_orbitHaltSpin];
    HFCurtainSheet *s = [HFCurtainSheet new];
    s.titleText = title;
    s.bodyText = body;
    s.leftTitle = @"Cancel";
    s.rightTitle = @"Confirm";
    s.tier = HFCurtainTierMid;
    s.onLeft = onCancel;
    s.onRight = ^{
        if (onSettings) onSettings();
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    };
    return [self hf_curtainSheet:s];
}

- (id)hf_curtainOrderSuccess:(void (^)(void))onConfirm {
    // docs_phl/19 + design: Success! / fixed body / Confirm only (no close / no Feedback).
    HFCurtainSheet *s = [HFCurtainSheet new];
    s.titleText = @"Success!";
    s.bodyText = @"Your application is under review. Once approved, the money will be credited to your bank account.";
    s.rightTitle = @"Confirm";
    s.showClose = NO;
    s.tier = HFCurtainTierMid;
    s.onRight = ^{
        if (onConfirm) onConfirm();
    };
    return [self hf_curtainSheet:s];
}

@end
