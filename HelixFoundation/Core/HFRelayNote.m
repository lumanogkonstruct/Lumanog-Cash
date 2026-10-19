#import "HFRelayNote.h"
#import "HFLatticeKit.h"
#import "HFOrbitHint.h"
#import "HFLedgerFetch.h"
#import "HFParcelModels.h"
#import <Masonry/Masonry.h>

@interface HFRelayNote ()
@property (nonatomic, strong) UIScrollView *hf_scroll;
@property (nonatomic, strong) UIView *hf_content;
@property (nonatomic, strong) UILabel *hf_mailCaption;
@property (nonatomic, strong) UIView *hf_mailCard;
@property (nonatomic, strong) UILabel *hf_mailValue;
@property (nonatomic, strong) UIButton *hf_mailCopy;
@property (nonatomic, strong) UILabel *hf_webCaption;
@property (nonatomic, strong) UIView *hf_webCard;
@property (nonatomic, strong) UILabel *hf_webValue;
@property (nonatomic, strong) UIButton *hf_webCopy;
@property (nonatomic, strong) UILabel *hf_bodyLab;
@property (nonatomic, copy) NSString *hf_mailText;
@property (nonatomic, copy) NSString *hf_webText;
@end

@implementation HFRelayNote

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = @"Repayment instructions";
    self.title = self.hf_navTitle;
    self.hf_mailText = @"Not available";
    self.hf_webText = @"Not available";
    [self hf_buildChrome];
    [self hf_loadConfig];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - UI

- (void)hf_buildChrome {
    UIColor *captionColor = [UIColor hf_prismHex:@"#8A8178"];
    UIColor *valueColor = [UIColor hf_prismInk];

    self.hf_scroll = [UIScrollView new];
    self.hf_scroll.alwaysBounceVertical = YES;
    self.hf_scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.hf_scroll];

    self.hf_content = [UIView new];
    [self.hf_scroll addSubview:self.hf_content];

    self.hf_mailCaption = [self hf_caption:@"Customer service email" color:captionColor];
    self.hf_mailCard = [self hf_roundCard];
    self.hf_mailValue = [self hf_valueLab:valueColor];
    self.hf_mailCopy = [self hf_copyBtn];
    self.hf_mailCopy.userInteractionEnabled = NO;
    [self.hf_mailCard addSubview:self.hf_mailValue];
    [self.hf_mailCard addSubview:self.hf_mailCopy];
    [self.hf_content addSubview:self.hf_mailCaption];
    [self.hf_content addSubview:self.hf_mailCard];
    UITapGestureRecognizer *mailTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hf_tapMailCopy)];
    [self.hf_mailCard addGestureRecognizer:mailTap];

    self.hf_webCaption = [self hf_caption:@"Official website link" color:captionColor];
    self.hf_webCard = [self hf_roundCard];
    self.hf_webValue = [self hf_valueLab:valueColor];
    self.hf_webCopy = [self hf_copyBtn];
    self.hf_webCopy.userInteractionEnabled = NO;
    [self.hf_webCard addSubview:self.hf_webValue];
    [self.hf_webCard addSubview:self.hf_webCopy];
    [self.hf_content addSubview:self.hf_webCaption];
    [self.hf_content addSubview:self.hf_webCard];
    UITapGestureRecognizer *webTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hf_tapWebCopy)];
    [self.hf_webCard addGestureRecognizer:webTap];

    self.hf_bodyLab = [UILabel new];
    self.hf_bodyLab.numberOfLines = 0;
    self.hf_bodyLab.textColor = captionColor;
    self.hf_bodyLab.font = [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular];
    [self.hf_content addSubview:self.hf_bodyLab];

    [self.hf_scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.hf_content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.hf_scroll);
        make.width.equalTo(self.hf_scroll);
    }];

    [self.hf_mailCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_content).offset(28);
        make.leading.equalTo(self.hf_content).offset(24);
        make.trailing.equalTo(self.hf_content).offset(-24);
    }];
    [self.hf_mailCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_mailCaption.mas_bottom).offset(12);
        make.leading.equalTo(self.hf_content).offset(24);
        make.trailing.equalTo(self.hf_content).offset(-24);
        make.height.mas_greaterThanOrEqualTo(52);
    }];
    [self.hf_mailCopy mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.hf_mailCard).offset(-14);
        make.centerY.equalTo(self.hf_mailCard);
        make.width.height.mas_equalTo(24);
    }];
    [self.hf_mailValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.hf_mailCard).offset(16);
        make.trailing.equalTo(self.hf_mailCopy.mas_leading).offset(-10);
        make.top.equalTo(self.hf_mailCard).offset(14);
        make.bottom.equalTo(self.hf_mailCard).offset(-14);
    }];

    [self.hf_webCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_mailCard.mas_bottom).offset(24);
        make.leading.trailing.equalTo(self.hf_mailCaption);
    }];
    [self.hf_webCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_webCaption.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.hf_mailCard);
        make.height.mas_greaterThanOrEqualTo(52);
    }];
    [self.hf_webCopy mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.hf_webCard).offset(-14);
        make.centerY.equalTo(self.hf_webCard);
        make.width.height.mas_equalTo(24);
    }];
    [self.hf_webValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.hf_webCard).offset(16);
        make.trailing.equalTo(self.hf_webCopy.mas_leading).offset(-10);
        make.top.equalTo(self.hf_webCard).offset(14);
        make.bottom.equalTo(self.hf_webCard).offset(-14);
    }];

    [self.hf_bodyLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_webCard.mas_bottom).offset(28);
        make.leading.equalTo(self.hf_content).offset(24);
        make.trailing.equalTo(self.hf_content).offset(-24);
        make.bottom.equalTo(self.hf_content).offset(-32);
    }];

    [self hf_applyValues];
}

- (UILabel *)hf_caption:(NSString *)text color:(UIColor *)color {
    UILabel *l = [UILabel new];
    l.text = text;
    l.textColor = color;
    l.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    l.textAlignment = NSTextAlignmentCenter;
    return l;
}

- (UIView *)hf_roundCard {
    UIView *v = [UIView new];
    v.backgroundColor = UIColor.whiteColor;
    v.layer.cornerRadius = 16;
    v.userInteractionEnabled = YES;
    return v;
}

- (UILabel *)hf_valueLab:(UIColor *)color {
    UILabel *l = [UILabel new];
    l.textColor = color;
    l.font = [UIFont hf_latticeGlyph:15 mass:UIFontWeightRegular];
    l.numberOfLines = 0;
    return l;
}

- (UIButton *)hf_copyBtn {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setImage:[UIImage imageNamed:@"one_icon_copy"] forState:UIControlStateNormal];
    b.imageView.contentMode = UIViewContentModeScaleAspectFit;
    return b;
}

- (void)hf_applyValues {
    self.hf_mailValue.text = self.hf_mailText.length ? self.hf_mailText : @"Not available";
    self.hf_webValue.text = self.hf_webText.length ? self.hf_webText : @"Not available";
    self.hf_bodyLab.attributedText = [self hf_bodyAttr];
}

- (NSAttributedString *)hf_bodyAttr {
    NSString *site = self.hf_webText.length ? self.hf_webText : @"Not available";
    NSString *p1 = [NSString stringWithFormat:
                    @"When making repayments, we kindly request you to first use the app to obtain the repayment link. In case the app is not accessible, you may also log in to our official website for repayment: %@. Please note that if the repayment link used is different from the one displayed on the app or official website, it will be considered a repayment failure.",
                    site];
    NSString *p2 = @"If someone contacts you to split the total repayment amount into multiple payments, or sends you a repayment link that does not match what is displayed on the app or official website, please contact customer service for assistance. After verifying the situation, we will waive the service fee for you.";
    NSString *p3 = @"If you encounter any suspicious situations during the repayment process, please contact customer service via email first. We will promptly assist you to resolve any issues.";
    NSString *p4 = @"For the safety of your funds, please read the repayment instructions carefully before proceeding with repayment";
    NSString *full = [NSString stringWithFormat:@"%@\n\n%@\n\n%@\n\n%@", p1, p2, p3, p4];

    UIColor *normal = [UIColor hf_prismHex:@"#8A8178"];
    UIColor *strong = [UIColor hf_prismHex:@"#50433B"];
    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithString:full attributes:@{
        NSFontAttributeName: [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular],
        NSForegroundColorAttributeName: normal
    }];
    NSRange r4 = [full rangeOfString:p4];
    if (r4.location != NSNotFound) {
        [m addAttribute:NSForegroundColorAttributeName value:strong range:r4];
        [m addAttribute:NSFontAttributeName value:[UIFont hf_latticeGlyph:13 mass:UIFontWeightMedium] range:r4];
    }
    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
    ps.lineSpacing = 4;
    ps.alignment = NSTextAlignmentLeft;
    [m addAttribute:NSParagraphStyleAttributeName value:ps range:NSMakeRange(0, m.length)];
    return m;
}

#pragma mark - Data

- (void)hf_loadConfig {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFLedgerFetch shared] hf_ledgerObtain:^(HFParcelConfig * _Nullable cfg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [[HFOrbitHint shared] hf_orbitHaltSpin];
            if (!cfg) {
                [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
                [self hf_applyValues];
                return;
            }
            self.hf_mailText = cfg.appEmail.length ? cfg.appEmail : @"Not available";
            self.hf_webText = cfg.officialWebsiteUrl.length ? cfg.officialWebsiteUrl : @"Not available";
            [self hf_applyValues];
        });
    }];
}

#pragma mark - Copy

- (void)hf_copyText:(NSString *)text successToast:(NSString *)toast {
    if (!text.length || [text isEqualToString:@"Not available"]) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Not available"];
        return;
    }
    UIPasteboard.generalPasteboard.string = text;
    [[HFOrbitHint shared] hf_orbitPulse:toast];
}

- (void)hf_tapMailCopy {
    [self hf_copyText:self.hf_mailText successToast:@"The Email has been copied to the clipboard."];
}

- (void)hf_tapWebCopy {
    [self hf_copyText:self.hf_webText successToast:@"The link has been copied to the clipboard."];
}

@end
