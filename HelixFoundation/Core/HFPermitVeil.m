#import "HFPermitVeil.h"
#import "HFCurtainBox.h"
#import "HFLatticeKit.h"
#import <Masonry/Masonry.h>

static const NSInteger kHFPermitLensTag = 0x4C656E73;

@interface HFPermitHostOverlay : UIView
@property (nonatomic, copy, nullable) void (^hf_onConfirm)(void);
@property (nonatomic, copy, nullable) void (^hf_onCancel)(void);
@end

@implementation HFPermitHostOverlay

- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    UIControl *veil = [UIControl new];
    veil.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    [veil addTarget:self action:@selector(hf_tapCancel) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:veil];
    [veil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    UIView *card = [UIView new];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 18;
    card.clipsToBounds = YES;
    [self addSubview:card];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.leading.equalTo(self).offset(36);
        make.trailing.equalTo(self).offset(-36);
    }];

    UILabel *titleLab = [UILabel new];
    titleLab.text = title;
    titleLab.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightRegular];
    titleLab.textColor = [UIColor hf_prismInk];
    titleLab.textAlignment = NSTextAlignmentCenter;
    titleLab.numberOfLines = 0;

    UILabel *bodyLab = [UILabel new];
    bodyLab.text = body;
    bodyLab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    bodyLab.textColor = [UIColor hf_prismInk];
    bodyLab.textAlignment = NSTextAlignmentCenter;
    bodyLab.numberOfLines = 0;

    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor hf_prismInk] forState:UIControlStateNormal];
    cancelBtn.titleLabel.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightSemibold];
    cancelBtn.backgroundColor = [UIColor hf_prismHex:@"#F5EDE2"];
    cancelBtn.layer.cornerRadius = 22;
    [cancelBtn addTarget:self action:@selector(hf_tapCancel) forControlEvents:UIControlEventTouchUpInside];

    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmBtn setTitle:@"Confirm" forState:UIControlStateNormal];
    [confirmBtn setTitleColor:[UIColor hf_prismInk] forState:UIControlStateNormal];
    confirmBtn.titleLabel.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightSemibold];
    confirmBtn.backgroundColor = [UIColor hf_prismTheme];
    confirmBtn.layer.cornerRadius = 22;
    [confirmBtn addTarget:self action:@selector(hf_tapConfirm) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *btnRow = [[UIStackView alloc] initWithArrangedSubviews:@[cancelBtn, confirmBtn]];
    btnRow.axis = UILayoutConstraintAxisHorizontal;
    btnRow.spacing = 12;
    btnRow.distribution = UIStackViewDistributionFillEqually;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLab, bodyLab, btnRow]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 14;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(28, 20, 24, 20));
    }];
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
    }];
    [confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
    }];
    return self;
}

- (void)hf_dismissThen:(void (^)(void))then {
    [UIView animateWithDuration:0.18 animations:^{
        self.alpha = 0;
    } completion:^(__unused BOOL finished) {
        [self removeFromSuperview];
        if (then) then();
    }];
}

- (void)hf_tapCancel {
    __weak typeof(self) weakSelf = self;
    [self hf_dismissThen:^{
        if (weakSelf.hf_onCancel) weakSelf.hf_onCancel();
    }];
}

- (void)hf_tapConfirm {
    __weak typeof(self) weakSelf = self;
    [self hf_dismissThen:^{
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        if (weakSelf.hf_onConfirm) weakSelf.hf_onConfirm();
    }];
}

@end

@implementation HFPermitVeil

+ (NSString *)hf_permitAppName {
    NSString *n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!n.length) n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return n.length ? n : @"App";
}

+ (NSString *)hf_permitTitle:(HFPermitKind)kind {
    switch (kind) {
        case HFPermitKindRoster: return @"Contacts";
        case HFPermitKindLens: return @"Camera";
        case HFPermitKindVisage: return @"Face ID";
        case HFPermitKindLocate:
        default: return @"Location";
    }
}

+ (NSString *)hf_permitBody:(HFPermitKind)kind {
    NSString *app = [self hf_permitAppName];
    switch (kind) {
        case HFPermitKindRoster:
            return [NSString stringWithFormat:@"%@ needs to access your contacts to perform fraud detection. This process helps us verify your identity and ensure the security of your account. To avoid affecting the review results, please select \"Allow Full Access\" when authorizing. We attach great importance to your privacy, and your contact information will be uploaded to our server, but will not be stored or shared with third parties. You can change your authorization at any time in the settings.", app];
        case HFPermitKindLens:
            return [NSString stringWithFormat:@"Please allow %@ to access camera in the settings so that you can take photos", app];
        case HFPermitKindVisage:
            return @"Enable Face ID for a faster and easier sign-in experience. You’ll be able to access your account instantly with just one tap on your next visit.";
        case HFPermitKindLocate:
        default:
            return [NSString stringWithFormat:@"Please allow %@ to access location in the settings so that you can complete the loan application", app];
    }
}

+ (id)hf_permitPresent:(HFPermitKind)kind
               confirm:(void (^)(void))onConfirm
                cancel:(void (^)(void))onCancel {
    return [[HFCurtainBox shared] hf_curtainPermTitle:[self hf_permitTitle:kind]
                                                 body:[self hf_permitBody:kind]
                                              confirm:onConfirm
                                               cancel:onCancel];
}

+ (void)hf_permitDismiss:(id)token {
    if (token) [[HFCurtainBox shared] hf_curtainDismiss:token];
}

+ (UIView *)hf_permitPresentOnHost:(UIView *)host
                              kind:(HFPermitKind)kind
                           confirm:(void (^)(void))onConfirm
                            cancel:(void (^)(void))onCancel {
    if (!host) return nil;
    if (kind == HFPermitKindLens) {
        [[host viewWithTag:kHFPermitLensTag] removeFromSuperview];
    }
    HFPermitHostOverlay *overlay = [[HFPermitHostOverlay alloc] initWithTitle:[self hf_permitTitle:kind]
                                                                         body:[self hf_permitBody:kind]];
    if (kind == HFPermitKindLens) overlay.tag = kHFPermitLensTag;
    overlay.hf_onConfirm = onConfirm;
    overlay.hf_onCancel = onCancel;
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    [host addSubview:overlay];
    [host bringSubviewToFront:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(host);
    }];
    overlay.alpha = 0;
    [UIView animateWithDuration:0.22 animations:^{
        overlay.alpha = 1;
    }];
    return overlay;
}

+ (void)hf_permitDismissHost:(UIView *)overlay {
    if (![overlay isKindOfClass:[UIView class]] || !overlay.superview) return;
    [UIView animateWithDuration:0.18 animations:^{
        overlay.alpha = 0;
    } completion:^(__unused BOOL finished) {
        [overlay removeFromSuperview];
    }];
}

@end
