#import "HFDockLeaf.h"
#import "HFLatticeKit.h"
#import "HFOrbitHint.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFLedgerFetch.h"
#import "HFCurtainBox.h"
#import "HFParcelModels.h"
#import "HFPaneBrowse.h"
#import "HFMintPier.h"
#import "HFBeaconNest.h"
#import "HFDockBar.h"
#import "HFDriftNest.h"
#import "HFMatchNest.h"
#import "HFPraiseGate.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <AdjustSdk/Adjust.h>
#import "AppDelegate.h"

static BOOL sHFHomeSoftUpdateShown = NO;
/// Once per process — each cold start uploads adid when entering home.
static BOOL sHFAdidUploadedThisLaunch = NO;

@interface HFDockLeafHome ()
@property (nonatomic, strong) UIView *hf_statusFill;
@property (nonatomic, strong) UIScrollView *hf_scroll;
@property (nonatomic, strong) UIView *hf_content;
@property (nonatomic, strong) UIView *hf_headerBand;
@property (nonatomic, strong) UIImageView *hf_logoView;
@property (nonatomic, strong) UILabel *hf_appNameLab;
@property (nonatomic, strong) UIButton *hf_feedbackBtn;
@property (nonatomic, strong) UIView *hf_promptRow;
@property (nonatomic, strong) UILabel *hf_promptLab;
@property (nonatomic, assign) CGFloat hf_promptLaidWidth;
@property (nonatomic, strong) UIView *hf_actionRow;
@property (nonatomic, strong) UIStackView *hf_bodyStack;
@property (nonatomic, strong) UIView *hf_quotaCard;
@property (nonatomic, strong) UILabel *hf_quotaAmountLab;
@property (nonatomic, strong) UILabel *hf_quotaTitleLab;
@property (nonatomic, strong) UILabel *hf_quotaRateLab;
@property (nonatomic, strong) UIView *hf_quotaRateBox;
@property (nonatomic, strong) UILabel *hf_quotaTermLab;
@property (nonatomic, strong) UIView *hf_quotaTermBox;
@property (nonatomic, strong) UIButton *hf_quotaApplyBtn;
@property (nonatomic, strong) UIImageView *hf_homeBannerIV;

@property (nonatomic, strong, nullable) HFParcelHome *hf_home;
@property (nonatomic, strong, nullable) HFParcelVersion *hf_version;
@property (nonatomic, strong, nullable) HFParcelConfig *hf_config;
@property (nonatomic, strong, nullable) HFParcelProductList *hf_products;

@property (nonatomic, assign) BOOL hf_pipeReady;
@property (nonatomic, assign) BOOL hf_pipeBusy;
@property (nonatomic, assign) BOOL hf_adidBusy;
@property (nonatomic, assign) NSInteger hf_lastStatus;
@property (nonatomic, strong, nullable) MASConstraint *hf_logoTopConstraint;
@end

@implementation HFDockLeafHome

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = @"";
    self.hf_lastStatus = NSNotFound;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hf_homeOnAdjustReady)
                                                 name:HFAdjustDidInitNotification
                                               object:nil];
    [self hf_homeBuildChrome];
    [self hf_homeRunFullPipe];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HFAdjustDidInitNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    if (self.hf_pipeReady && !self.hf_pipeBusy) {
        [self hf_homeSoftRefresh];
    }
    // Every app open → home: ensure adid upload once (Adjust may init after first pipe).
    [self hf_homeUploadAdidIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Logo must stay inside scroll content (not pinned to view.safeArea) or the list cannot scroll.
    [self.hf_logoTopConstraint setOffset:self.view.safeAreaInsets.top + 8.0];
    CGFloat w = CGRectGetWidth(self.hf_promptRow.bounds);
    if (w < 1 || self.hf_promptRow.hidden) return;
    if (fabs(w - self.hf_promptLaidWidth) < 0.5) return;
    self.hf_promptLaidWidth = w;
    NSString *copy = self.hf_home.promptCopy ?: @"";
    if (copy.length) [self hf_homeApplyPromptText:copy];
}

#pragma mark - Chrome

- (void)hf_homeBuildChrome {
    UIColor *ink = [UIColor hf_prismInk];
    UIColor *base = [UIColor hf_prismHex:@"#F5EDE2"];
    // Remaining areas (below header / tab gap) stay base beige.
    self.view.backgroundColor = base;
    self.hf_canvasTint = base;

    self.hf_scroll = [UIScrollView new];
    self.hf_scroll.alwaysBounceVertical = YES;
    self.hf_scroll.showsVerticalScrollIndicator = NO;
    self.hf_scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.hf_scroll.backgroundColor = base;
    [self.view addSubview:self.hf_scroll];

    self.hf_content = [UIView new];
    self.hf_content.backgroundColor = base;
    [self.hf_scroll addSubview:self.hf_content];

    self.hf_headerBand = [UIView new];
    self.hf_headerBand.backgroundColor = ink;
    [self.hf_content addSubview:self.hf_headerBand];

    // Keep status-bar strip #50433B while body remains #F5EDE2.
    self.hf_statusFill = [UIView new];
    self.hf_statusFill.backgroundColor = ink;
    [self.view addSubview:self.hf_statusFill];

    self.hf_logoView = [UIImageView new];
    self.hf_logoView.image = [UIImage imageNamed:@"logo"];
    self.hf_logoView.contentMode = UIViewContentModeScaleAspectFill;
    self.hf_logoView.clipsToBounds = YES;
    self.hf_logoView.backgroundColor = UIColor.whiteColor;
    self.hf_logoView.layer.cornerRadius = 18;
    [self.hf_headerBand addSubview:self.hf_logoView];

    self.hf_appNameLab = [UILabel new];
    self.hf_appNameLab.text = [self hf_homeAppName];
    self.hf_appNameLab.textColor = UIColor.whiteColor;
    self.hf_appNameLab.font = [UIFont hf_latticeGlyph:18 mass:UIFontWeightRegular];
    [self.hf_headerBand addSubview:self.hf_appNameLab];

    self.hf_feedbackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *fb = [[UIImage imageNamed:@"one_icon_feedback"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.hf_feedbackBtn setImage:fb forState:UIControlStateNormal];
    self.hf_feedbackBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.hf_feedbackBtn.adjustsImageWhenHighlighted = NO;
    [self.hf_feedbackBtn addTarget:self action:@selector(hf_homeTapFeedback) forControlEvents:UIControlEventTouchUpInside];
    [self.hf_headerBand addSubview:self.hf_feedbackBtn];

    self.hf_promptRow = [UIView new];
    self.hf_promptRow.hidden = YES;
    self.hf_promptRow.userInteractionEnabled = YES;
    UITapGestureRecognizer *promptTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hf_homeTapPrompt)];
    [self.hf_promptRow addGestureRecognizer:promptTap];
    [self.hf_headerBand addSubview:self.hf_promptRow];

    self.hf_promptLab = [UILabel new];
    self.hf_promptLab.textColor = UIColor.whiteColor;
    self.hf_promptLab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    self.hf_promptLab.numberOfLines = 0;
    self.hf_promptLab.lineBreakMode = NSLineBreakByWordWrapping;
    [self.hf_promptRow addSubview:self.hf_promptLab];

    self.hf_actionRow = [UIView new];
    [self.hf_content addSubview:self.hf_actionRow];
    [self hf_homeBuildActionCards];

    self.hf_bodyStack = [[UIStackView alloc] init];
    self.hf_bodyStack.axis = UILayoutConstraintAxisVertical;
    self.hf_bodyStack.spacing = 12; // card → dssl_home_sb follows closely
    [self.hf_content addSubview:self.hf_bodyStack];

    [self hf_homeBuildQuotaCard];
    [self hf_homeBuildBanner];

    [self.hf_bodyStack addArrangedSubview:self.hf_quotaCard];
    [self.hf_bodyStack addArrangedSubview:self.hf_homeBannerIV];

    [self.view bringSubviewToFront:self.hf_statusFill];

    [self.hf_statusFill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop);
    }];
    [self.hf_scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    [self.hf_content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.bottom.equalTo(self.hf_scroll);
        make.width.equalTo(self.hf_scroll);
    }];
    [self.hf_headerBand mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.hf_content);
    }];
    [self.hf_logoView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.hf_logoTopConstraint = make.top.equalTo(self.hf_headerBand).offset(54);
        make.leading.equalTo(self.hf_headerBand).offset(16);
        make.width.height.mas_equalTo(36);
    }];
    [self.hf_appNameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.hf_logoView);
        make.leading.equalTo(self.hf_logoView.mas_trailing).offset(8);
    }];
    [self.hf_feedbackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.hf_logoView);
        make.trailing.equalTo(self.hf_headerBand).offset(-16);
        make.height.mas_equalTo(32);
        make.width.mas_equalTo(109); // asset ~218x64 @2x → 109x32
        make.leading.greaterThanOrEqualTo(self.hf_appNameLab.mas_trailing).offset(8);
    }];
    [self.hf_promptRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_logoView.mas_bottom).offset(14);
        make.leading.equalTo(self.hf_headerBand).offset(16);
        make.trailing.equalTo(self.hf_headerBand).offset(-16);
        make.bottom.equalTo(self.hf_headerBand).offset(-54);
    }];
    [self.hf_promptLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.hf_promptRow);
    }];
    [self.hf_actionRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_headerBand.mas_bottom).offset(-40);
        make.leading.equalTo(self.hf_content).offset(16);
        make.trailing.equalTo(self.hf_content).offset(-16);
        make.height.mas_equalTo(108);
    }];
    [self.hf_bodyStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_actionRow.mas_bottom).offset(16);
        make.leading.equalTo(self.hf_content).offset(16);
        make.trailing.equalTo(self.hf_content).offset(-16);
        make.bottom.equalTo(self.hf_content).offset(-16);
    }];
}

- (void)hf_homeBuildActionCards {
    NSArray *items = @[
        @{ @"title": @"Bank\nAccount", @"icon": @"one_icon_bank", @"bg": @"#FFFFFF", @"tag": @1 },
        @{ @"title": @"Contact\nus", @"icon": @"one_icon_contact", @"bg": @"#EFA37A", @"tag": @2 },
        @{ @"title": @"Official\nWebsite", @"icon": @"one_icon_official", @"bg": @"#B7D0D3", @"tag": @3 },
    ];
    UIView *prev = nil;
    for (NSInteger i = 0; i < (NSInteger)items.count; i++) {
        NSDictionary *it = items[i];
        UIButton *card = [UIButton buttonWithType:UIButtonTypeCustom];
        card.backgroundColor = [UIColor hf_prismHex:it[@"bg"]];
        card.layer.cornerRadius = 14;
        card.clipsToBounds = YES;
        card.tag = [it[@"tag"] integerValue];
        [card addTarget:self action:@selector(hf_homeTapAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.hf_actionRow addSubview:card];

        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:it[@"icon"]]];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.userInteractionEnabled = NO;
        [card addSubview:iv];

        UILabel *lab = [UILabel new];
        lab.text = it[@"title"];
        lab.textColor = [UIColor hf_prismInk];
        lab.font = [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular];
        lab.textAlignment = NSTextAlignmentLeft;
        lab.numberOfLines = 2;
        lab.userInteractionEnabled = NO;
        [card addSubview:lab];

        [iv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(card).offset(18);
            make.leading.equalTo(card).offset(12);
            make.width.height.mas_equalTo(28);
        }];
        [lab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(iv.mas_bottom).offset(8);
            make.leading.equalTo(card).offset(12);
            make.trailing.equalTo(card).offset(-8);
        }];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.hf_actionRow);
            if (prev) {
                make.leading.equalTo(prev.mas_trailing).offset(10);
                make.width.equalTo(prev);
            } else {
                make.leading.equalTo(self.hf_actionRow);
            }
            if (i == (NSInteger)items.count - 1) {
                make.trailing.equalTo(self.hf_actionRow);
            }
        }];
        prev = card;
    }
}

/// docs_phl/52 §2.1 — single quota card, aspect 335:216
- (void)hf_homeBuildQuotaCard {
    UIColor *ink = [UIColor hf_prismInk];
    UIColor *chipBG = [UIColor hf_prismHex:@"#F5EDE2"];

    self.hf_quotaCard = [UIView new];
    self.hf_quotaCard.backgroundColor = UIColor.whiteColor;
    self.hf_quotaCard.layer.cornerRadius = 16;
    self.hf_quotaCard.clipsToBounds = YES;
    [self.hf_quotaCard setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.hf_quotaCard setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

    self.hf_quotaAmountLab = [UILabel new];
    self.hf_quotaAmountLab.text = @"--";
    self.hf_quotaAmountLab.textColor = UIColor.blackColor;
    self.hf_quotaAmountLab.font = [UIFont hf_latticeGlyph:32 mass:UIFontWeightSemibold];
    self.hf_quotaAmountLab.textAlignment = NSTextAlignmentCenter;
    self.hf_quotaAmountLab.adjustsFontSizeToFitWidth = YES;
    self.hf_quotaAmountLab.minimumScaleFactor = 0.6;
    [self.hf_quotaCard addSubview:self.hf_quotaAmountLab];

    self.hf_quotaTitleLab = [UILabel new];
    self.hf_quotaTitleLab.text = @"Maximum Loan Amount";
    self.hf_quotaTitleLab.textColor = [UIColor hf_prismHex:@"#9A9A9A"];
    self.hf_quotaTitleLab.font = [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular];
    self.hf_quotaTitleLab.textAlignment = NSTextAlignmentCenter;
    [self.hf_quotaCard addSubview:self.hf_quotaTitleLab];

    self.hf_quotaRateBox = [UIView new];
    self.hf_quotaRateBox.backgroundColor = chipBG;
    self.hf_quotaRateBox.layer.cornerRadius = 12;
    self.hf_quotaRateBox.clipsToBounds = YES;
    self.hf_quotaRateLab = [UILabel new];
    self.hf_quotaRateLab.textColor = UIColor.blackColor;
    self.hf_quotaRateLab.font = [UIFont hf_latticeGlyph:12 mass:UIFontWeightRegular];
    self.hf_quotaRateLab.textAlignment = NSTextAlignmentCenter;
    [self.hf_quotaRateBox addSubview:self.hf_quotaRateLab];
    [self.hf_quotaRateBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(100);
    }];
    [self.hf_quotaRateLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.hf_quotaRateBox).insets(UIEdgeInsetsMake(6, 4, 6, 4));
    }];

    self.hf_quotaTermBox = [UIView new];
    self.hf_quotaTermBox.backgroundColor = chipBG;
    self.hf_quotaTermBox.layer.cornerRadius = 12;
    self.hf_quotaTermBox.clipsToBounds = YES;
    self.hf_quotaTermLab = [UILabel new];
    self.hf_quotaTermLab.textColor = UIColor.blackColor;
    self.hf_quotaTermLab.font = [UIFont hf_latticeGlyph:12 mass:UIFontWeightRegular];
    self.hf_quotaTermLab.textAlignment = NSTextAlignmentCenter;
    [self.hf_quotaTermBox addSubview:self.hf_quotaTermLab];
    [self.hf_quotaTermBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(100);
    }];
    [self.hf_quotaTermLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.hf_quotaTermBox).insets(UIEdgeInsetsMake(6, 4, 6, 4));
    }];

    UIStackView *tags = [[UIStackView alloc] initWithArrangedSubviews:@[ self.hf_quotaRateBox, self.hf_quotaTermBox ]];
    tags.axis = UILayoutConstraintAxisHorizontal;
    tags.alignment = UIStackViewAlignmentCenter;
    tags.spacing = 10;
    tags.tag = 9021;
    [self.hf_quotaCard addSubview:tags];

    self.hf_quotaApplyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.hf_quotaApplyBtn.backgroundColor = [UIColor hf_prismTheme];
    self.hf_quotaApplyBtn.layer.cornerRadius = 24;
    [self.hf_quotaApplyBtn setTitle:@"APPLY" forState:UIControlStateNormal];
    [self.hf_quotaApplyBtn setTitleColor:ink forState:UIControlStateNormal];
    self.hf_quotaApplyBtn.titleLabel.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightRegular];
    [self.hf_quotaApplyBtn addTarget:self action:@selector(hf_homeTapQuotaApply) forControlEvents:UIControlEventTouchUpInside];
    [self.hf_quotaCard addSubview:self.hf_quotaApplyBtn];

    [self.hf_quotaCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.hf_quotaCard.mas_width).multipliedBy(216.0 / 335.0);
    }];
    [self.hf_quotaAmountLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_quotaCard).offset(28);
        make.leading.equalTo(self.hf_quotaCard).offset(20);
        make.trailing.equalTo(self.hf_quotaCard).offset(-20);
    }];
    [self.hf_quotaTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_quotaAmountLab.mas_bottom).offset(6);
        make.leading.trailing.equalTo(self.hf_quotaAmountLab);
    }];
    [tags mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_quotaTitleLab.mas_bottom).offset(14);
        make.centerX.equalTo(self.hf_quotaCard);
    }];
    [self.hf_quotaApplyBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.hf_quotaCard).offset(24);
        make.trailing.equalTo(self.hf_quotaCard).offset(-24);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.hf_quotaCard).offset(-24);
    }];
}

- (void)hf_homeBuildBanner {
    self.hf_homeBannerIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dssl_home_sb"]];
    self.hf_homeBannerIV.contentMode = UIViewContentModeScaleAspectFit;
    self.hf_homeBannerIV.clipsToBounds = YES;
    [self.hf_homeBannerIV setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.hf_homeBannerIV mas_makeConstraints:^(MASConstraintMaker *make) {
        // Asset @2x 670×222 → 335:111
        make.height.equalTo(self.hf_homeBannerIV.mas_width).multipliedBy(111.0 / 335.0);
    }];
}

#pragma mark - Render

- (void)hf_homeRender {
    NSString *copy = self.hf_home.promptCopy ?: @"";
    BOOL showPrompt = copy.length > 0;
    self.hf_promptRow.hidden = !showPrompt;
    [self hf_homeApplyPromptText:copy];
    [self.hf_promptRow mas_updateConstraints:^(MASConstraintMaker *make) {
        if (showPrompt) {
            make.bottom.equalTo(self.hf_headerBand).offset(-54);
        } else {
            make.bottom.equalTo(self.hf_headerBand).offset(-48);
        }
    }];
    if (!showPrompt) {
        [self.hf_promptRow mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.hf_logoView.mas_bottom).offset(0);
            make.leading.equalTo(self.hf_headerBand).offset(16);
            make.trailing.equalTo(self.hf_headerBand).offset(-16);
            make.height.mas_equalTo(0);
            make.bottom.equalTo(self.hf_headerBand).offset(-48);
        }];
    } else {
        [self.hf_promptRow mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.hf_logoView.mas_bottom).offset(14);
            make.leading.equalTo(self.hf_headerBand).offset(16);
            make.trailing.equalTo(self.hf_headerBand).offset(-16);
            make.bottom.equalTo(self.hf_headerBand).offset(-54);
        }];
    }

    [self hf_homeRefreshQuotaCard];
}

/// docs_phl/52 §2.1 — single-card amount: prefer home `maxApplyAmount`, else product/list highAmount
- (void)hf_homeRefreshQuotaCard {
    HFParcelProductInfo *p = self.hf_products.productInfoList.firstObject;
    NSString *rawAmt = @"";
    if (self.hf_home.maxApplyAmount.length) {
        rawAmt = self.hf_home.maxApplyAmount;
    } else if (p.highAmount.length) {
        rawAmt = p.highAmount;
    }
    NSString *amount = [self hf_homeMoney:rawAmt];
    self.hf_quotaAmountLab.text = amount.length ? amount : @"--";

    // Rate / term: hardcode per design mock (not from product/list)
    self.hf_quotaRateLab.text = @"0.08 %/day";
    self.hf_quotaRateBox.hidden = NO;
    self.hf_quotaTermLab.text = @"180 days";
    self.hf_quotaTermBox.hidden = NO;

    [self.hf_quotaApplyBtn setTitle:[self hf_homeQuotaButtonTitle] forState:UIControlStateNormal];
}

/// docs_phl/52 §2.2
- (NSString *)hf_homeQuotaButtonTitle {
    switch (self.hf_home.userStatus) {
        case 81: return @"Pay Overdue";
        case 41: return @"Change Bank Account";
        case 32: return @"Get loan";
        case 30: return @"Submit Application";
        default: return @"APPLY";
    }
}

#pragma mark - Format helpers

- (NSAttributedString *)hf_homePromptAttr:(NSString *)text showArrow:(BOOL)showArrow {
    UIFont *font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
    ps.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *base = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: UIColor.whiteColor,
        NSParagraphStyleAttributeName: ps,
    };
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text ?: @"" attributes:base];
    if (!showArrow) return attr;
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\u2009" attributes:base]];
    UIImage *arrow = [[UIImage imageNamed:@"one_icon_right_al"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    if (!arrow) return attr;
    CGFloat arrowSide = ceil(font.lineHeight);
    NSTextAttachment *att = [NSTextAttachment new];
    att.image = arrow;
    CGFloat y = (font.capHeight - arrowSide) * 0.5;
    att.bounds = CGRectMake(0, y, arrowSide, arrowSide);
    [attr appendAttributedString:[NSAttributedString attributedStringWithAttachment:att]];
    return attr;
}

- (void)hf_homeApplyPromptText:(NSString *)text {
    if (text.length == 0) {
        self.hf_promptLab.attributedText = nil;
        return;
    }
    BOOL showArrow = [self hf_homePromptShowsArrow];
    self.hf_promptRow.userInteractionEnabled = showArrow;
    CGFloat w = CGRectGetWidth(self.hf_promptRow.bounds);
    if (w < 1) w = self.hf_promptLaidWidth;
    self.hf_promptLab.numberOfLines = 0;
    self.hf_promptLab.lineBreakMode = NSLineBreakByWordWrapping;
    if (w > 1) self.hf_promptLab.preferredMaxLayoutWidth = w;
    self.hf_promptLab.attributedText = [self hf_homePromptAttr:text showArrow:showArrow];
}

- (NSString *)hf_homeAppName {
    NSString *n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!n.length) n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return n.length ? n : @"App";
}

- (NSString *)hf_homeCurrency {
    return @"₱";
}

- (NSString *)hf_homeMoney:(NSString *)raw {
    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) return @"";
    NSString *g = [NSString hf_digitGrouped:raw];
    if (!g.length) return @"";
    return [NSString stringWithFormat:@"%@%@", [self hf_homeCurrency], g];
}

- (BOOL)hf_homeVersionLower:(NSString *)cur than:(NSString *)latest {
    if (!cur.length || !latest.length) return NO;
    NSArray *a = [cur componentsSeparatedByString:@"."];
    NSArray *b = [latest componentsSeparatedByString:@"."];
    NSInteger n = MAX(a.count, b.count);
    for (NSInteger i = 0; i < n; i++) {
        NSInteger av = (i < (NSInteger)a.count) ? [a[i] integerValue] : 0;
        NSInteger bv = (i < (NSInteger)b.count) ? [b[i] integerValue] : 0;
        if (av < bv) return YES;
        if (av > bv) return NO;
    }
    return NO;
}

#pragma mark - Pipeline

- (void)hf_homeRunFullPipe {
    if (self.hf_pipeBusy) return;
    self.hf_pipeBusy = YES;
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;

    __block HFParcelHome *home = nil;
    __block HFParcelVersion *ver = nil;
    __block BOOL homeFail = NO;
    __block BOOL verFail = NO;
    dispatch_group_t g1 = dispatch_group_create();

    dispatch_group_enter(g1);
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pSupHome]
                              signMap:@{}
                           nonSignMap:@{ @"dcUpFlag": @"1" }
                           replyClass:[HFParcelHomeReply class]
                                   ok:^(HFParcelHomeReply *reply) {
        home = reply.data;
        dispatch_group_leave(g1);
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        homeFail = YES;
        dispatch_group_leave(g1);
    }];

    dispatch_group_enter(g1);
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pVersionV2]
                              signMap:@{}
                           nonSignMap:@{}
                           replyClass:[HFParcelVersionReply class]
                                   ok:^(HFParcelVersionReply *reply) {
        ver = reply.data;
        dispatch_group_leave(g1);
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        verFail = YES;
        dispatch_group_leave(g1);
    }];

    dispatch_group_notify(g1, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (homeFail || verFail) {
            [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
        }
        self.hf_home = home;
        self.hf_version = ver;
        [self hf_homeUploadAdidIfNeeded];

        [[HFLedgerFetch shared] hf_ledgerForce:^(HFParcelConfig * _Nullable cfg) {
            __strong typeof(weakSelf) self2 = weakSelf;
            if (!self2) return;
            self2.hf_config = cfg ?: [[HFLedgerFetch shared] hf_ledgerCache];

            NSInteger status = self2.hf_home.userStatus;
            if (status <= 10) {
                self2.hf_products = nil;
                [self2 hf_homeFinishFullPipe];
                return;
            }

            [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pProductList]
                                      signMap:@{}
                                   nonSignMap:@{}
                                   replyClass:[HFParcelProductListReply class]
                                           ok:^(HFParcelProductListReply *reply) {
                __strong typeof(weakSelf) self3 = weakSelf;
                if (!self3) return;
                self3.hf_products = reply.data;
                [self3 hf_homeFinishFullPipe];
            } fail:^(__unused NSString *msg, __unused NSString *code) {
                __strong typeof(weakSelf) self3 = weakSelf;
                if (!self3) return;
                [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
                self3.hf_products = nil;
                [self3 hf_homeFinishFullPipe];
            }];
        }];
    });
}

- (void)hf_homeFinishFullPipe {
    self.hf_pipeReady = YES;
    self.hf_lastStatus = self.hf_home.userStatus;
    [self hf_homeRender];
    self.hf_pipeBusy = NO;
    [[HFOrbitHint shared] hf_orbitHaltSpin];
    [self hf_homeTryAllDialogs];
}

- (void)hf_homeSoftRefresh {
    if (self.hf_pipeBusy) return;
    self.hf_pipeBusy = YES;
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pSupHome]
                              signMap:@{}
                           nonSignMap:@{ @"dcUpFlag": @"1" }
                           replyClass:[HFParcelHomeReply class]
                                   ok:^(HFParcelHomeReply *reply) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSInteger old = self.hf_lastStatus;
        self.hf_home = reply.data;
        NSInteger now = self.hf_home.userStatus;
        [[HFLedgerFetch shared] hf_ledgerForce:^(HFParcelConfig * _Nullable cfg) {
            __strong typeof(weakSelf) self2 = weakSelf;
            if (!self2) return;
            if (cfg) self2.hf_config = cfg;
            if (old != now && ((old <= 10 && now > 10) || (old > 10 && now <= 10))) {
                self2.hf_pipeBusy = NO;
                [[HFOrbitHint shared] hf_orbitHaltSpin];
                [self2 hf_homeRunFullPipe];
                return;
            }
            self2.hf_lastStatus = now;
            [self2 hf_homeRender];
            self2.hf_pipeBusy = NO;
            [[HFOrbitHint shared] hf_orbitHaltSpin];
            [self2 hf_homeTryWithdrawDialog];
            NSInteger kind = self2.hf_home.appUserType > 0 ? self2.hf_home.appUserType : 1;
            [[HFPraiseGate shared] hf_praiseRememberKind:kind];
            [self2 hf_homeUploadAdidIfNeeded];
        }];
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.hf_pipeBusy = NO;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
    }];
}

- (void)hf_homeOnAdjustReady {
    NSLog(@"[HFDockLeafHome] ADID Adjust ready — retry upload");
    [self hf_homeUploadAdidIfNeeded];
}

- (void)hf_homeUploadAdidIfNeeded {
    if (sHFAdidUploadedThisLaunch) return;
    if (self.hf_adidBusy) return;
    id del = UIApplication.sharedApplication.delegate;
    if ([del isKindOfClass:[AppDelegate class]] && ![(AppDelegate *)del hf_adjustReady]) {
        NSLog(@"[HFDockLeafHome] ADID wait — Adjust not inited yet");
        return;
    }
    self.hf_adidBusy = YES;
    NSLog(@"[HFDockLeafHome] ADID start — adidWithCompletionHandler");
    __weak typeof(self) weakSelf = self;
    [Adjust adidWithCompletionHandler:^(NSString * _Nullable adid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.hf_adidBusy = NO;
            NSString *trim = [adid isKindOfClass:[NSString class]]
                ? [adid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                : @"";
            if (trim.length == 0) {
                NSLog(@"[HFDockLeafHome] ADID empty — will retry on next home enter / Adjust ready");
                return;
            }
            if (sHFAdidUploadedThisLaunch) return;
            sHFAdidUploadedThisLaunch = YES;
            NSLog(@"[HFDockLeafHome] ADID post user/info adid=%@", trim);
            [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pUserInfo]
                                      signMap:@{}
                                   nonSignMap:@{ @"adid": trim }
                                   replyClass:[HFParcelUserReply class]
                                           ok:^(__unused HFParcelUserReply *reply) {
                NSLog(@"[HFDockLeafHome] ADID upload OK adid=%@", trim);
            } fail:^(NSString * _Nullable msg, NSString * _Nullable code) {
                sHFAdidUploadedThisLaunch = NO; // allow retry this launch
                NSLog(@"[HFDockLeafHome] ADID upload FAIL code=%@ msg=%@", code ?: @"", msg ?: @"");
            }];
        });
    }];
}

#pragma mark - Dialogs

- (void)hf_homeTryAllDialogs {
    [self hf_homeTrySoftUpdate];
    if (self.hf_home.userStatus > 10) {
        [self hf_homeTryWithdrawDialog];
    }
    // Cache appUserType only — 45 rate sheet is after order Success Confirm, not on home enter.
    NSInteger kind = self.hf_home.appUserType > 0 ? self.hf_home.appUserType : 1;
    [[HFPraiseGate shared] hf_praiseRememberKind:kind];
}

- (void)hf_homeTrySoftUpdate {
    if (sHFHomeSoftUpdateShown) return;
    HFParcelVersion *ver = self.hf_version;
    if (![ver.updateType isEqualToString:@"1"]) return;
    NSString *cur = [HFVaultSeal kIotaBundleRev];
    if (![self hf_homeVersionLower:cur than:ver.latestVersion]) return;
    sHFHomeSoftUpdateShown = YES;

    HFCurtainSheet *s = [HFCurtainSheet new];
    s.titleText = @"Upgrade";
    s.bodyText = @"New version found";
    s.leftTitle = @"Cancel";
    s.rightTitle = @"Upgrade";
    s.tier = HFCurtainTierHigh;
    s.onLeft = ^{};
    NSString *url = ver.latestVersionUrl ?: @"";
    s.onRight = ^{
        if (url.length == 0) return;
        NSURL *u = [NSURL URLWithString:url];
        if (u) [[UIApplication sharedApplication] openURL:u options:@{} completionHandler:nil];
    };
    [[HFCurtainBox shared] hf_curtainSheet:s];
}

- (void)hf_homeTryWithdrawDialog {
    if (self.hf_home.userStatus != 32) return;

    HFCurtainSheet *s = [HFCurtainSheet new];
    s.titleText = @"To be withdrawn";
    s.bodyText = @"You have an order pending withdrawal. After entering the page to confirm, the funds will be transferred to your bank account immediately.";
    s.leftTitle = @"Cancel";
    s.rightTitle = @"Withdraw";
    s.tier = HFCurtainTierMid;
    s.onLeft = ^{};
    __weak typeof(self) weakSelf = self;
    s.onRight = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSString *oid = [self.hf_home.withdrawalOrderId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        NSString *pid = [self.hf_home.orderStatusCount.productId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (oid.length == 0 && pid.length == 0) {
            [[HFOrbitHint shared] hf_orbitPulse:@"Missing order or product ID"];
            return;
        }
        NSMutableDictionary *ex = [NSMutableDictionary dictionary];
        if (oid.length) ex[@"orderId"] = oid;
        if (pid.length) ex[@"productId"] = pid;
        ex[@"orderType"] = @"1";
        [self hf_homeOpenH5:[HFVaultSeal kHrefOrderDetails] title:nil extras:ex];
    };
    [[HFCurtainBox shared] hf_curtainSheet:s];
}

#pragma mark - Product apply / intercept

/// docs_phl/52 §2.2 — single-card primary button
/// APPLY → 精准推荐页（动态加载 + dcRecommend）→ 产品申请 / 无产品 / 其它错误
- (void)hf_homeTapQuotaApply {
    NSInteger st = self.hf_home.userStatus;
    if (st == 10) {
        [self hf_homeOpenKYC];
        return;
    }
    if (st == 81) {
        [self hf_homeJumpOrderStatus:20];
        return;
    }
    if (st == 41 || st == 30 || st == 32) {
        [self hf_homeJumpOrderStatus:10];
        return;
    }
    HFMatchNest *vc = [HFMatchNest new];
    vc.hf_promptCopy = self.hf_home.promptCopy;
    vc.hf_userStatus = self.hf_home.userStatus;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)hf_homeRequestTerm:(NSString *)productId {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pProductTermV3]
                              signMap:@{ @"productId": productId ?: @"" }
                           nonSignMap:@{}
                           replyClass:[HFParcelProductTermReply class]
                                   ok:^(__unused HFParcelProductTermReply *reply) {
        __strong typeof(weakSelf) self = weakSelf;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        if (!self) return;
        [self hf_homeOpenH5:[HFVaultSeal kHrefProductApply] title:nil extras:@{ @"productId": productId ?: @"" }];
    } fail:^(NSString * _Nullable msg, NSString * _Nullable code) {
        __strong typeof(weakSelf) self = weakSelf;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        if (!self) return;
        if ([code isEqualToString:@"6230002"] || [code isEqualToString:@"6230003"]) {
            [self hf_homeShowIntercept:code productId:productId];
            return;
        }
        if ([code isEqualToString:@"6234303"]) {
            // Reject H5 when configured; empty → original toast (no forced jump).
            NSString *h5 = self.hf_config.dynamicParameter.rejectH5
                ?: [[HFLedgerFetch shared] hf_ledgerCache].dynamicParameter.rejectH5
                ?: @"";
            h5 = [h5 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            HFDriftNest *web = [HFDriftNest hf_driftWithURL:h5];
            if (web) {
                web.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:web animated:YES];
            } else {
                [[HFOrbitHint shared] hf_orbitPulse:msg.length ? msg : @"Failed to load product details"];
            }
            return;
        }
        [[HFOrbitHint shared] hf_orbitPulse:msg.length ? msg : @"Failed to load product details"];
    }];
}

- (nullable HFParcelProductInfo *)hf_homeProductById:(NSString *)productId {
    if (!productId.length) return nil;
    for (HFParcelProductInfo *p in self.hf_products.productInfoList) {
        if ([p.productId isEqualToString:productId]) return p;
    }
    return nil;
}

- (void)hf_homeShowIntercept:(NSString *)code productId:(NSString *)productId {
    HFCurtainSheet *s = [HFCurtainSheet new];
    s.titleText = @"Tips";
    s.bodyText = @"You have already applied for this product, and your current application is being processed. You cannot apply again at this time. You can view the order details or go back to choose another product to apply for.";
    s.leftTitle = @"Back";
    s.rightTitle = @"Know More";
    s.tier = HFCurtainTierMid;
    s.onLeft = ^{};
    __weak typeof(self) weakSelf = self;
    s.onRight = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSMutableDictionary *ex = [NSMutableDictionary dictionary];

        if ([code isEqualToString:@"6230003"]) {
            NSString *oid = self.hf_home.withdrawalOrderId ?: @"";
            NSString *pid = productId.length ? productId : (self.hf_home.orderStatusCount.productId ?: @"");
            if (oid.length) ex[@"orderId"] = oid;
            if (pid.length) ex[@"productId"] = pid;
            if (oid.length || pid.length) ex[@"orderType"] = @"1";
        } else {

            NSString *oid = self.hf_home.orderStatusCount.orderId ?: @"";
            if (!oid.length) {
                oid = [self hf_homeProductById:productId].lastOrderId ?: @"";
            }
            NSString *pid = productId.length ? productId : (self.hf_home.orderStatusCount.productId ?: @"");
            if (oid.length) ex[@"orderId"] = oid;
            if (pid.length) ex[@"productId"] = pid;
        }
        NSLog(@"[HFDockLeafHome] intercept Know More code=%@ extras=%@", code, ex);
        [self hf_homeOpenH5:[HFVaultSeal kHrefOrderDetails] title:nil extras:ex];
    };
    [[HFCurtainBox shared] hf_curtainSheet:s];
}

#pragma mark - Navigation helpers

- (void)hf_homeTapFeedback {
    [self hf_homeOpenH5:[HFVaultSeal kHrefFeedback] title:nil extras:@{}];
}

- (void)hf_homeTapPrompt {
    // docs_phl/18 §3.4 — prompt jump table only (100 / 20 etc. not listed → no jump)
    NSInteger st = self.hf_home.userStatus;
    if (st == 10) {
        [self hf_homeOpenKYC];
        return;
    }
    if (st == 81 || st == 80) {
        [self hf_homeJumpOrderStatus:20];
        return;
    }
    if (st == 41 || st == 30 || st == 32) {
        [self hf_homeJumpOrderStatus:10];
        return;
    }
    if (st == 51) {
        NSString *h5 = self.hf_config.dynamicParameter.rejectH5
            ?: [[HFLedgerFetch shared] hf_ledgerCache].dynamicParameter.rejectH5
            ?: @"";
        h5 = [h5 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (h5.length) {
            HFDriftNest *web = [HFDriftNest hf_driftWithURL:h5];
            if (web) {
                web.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:web animated:YES];
            }
        }
    }
}

- (BOOL)hf_homePromptShowsArrow {
    // docs_phl/18 §3.4 — arrow only when prompt has a jump target
    NSInteger st = self.hf_home.userStatus;
    if (st == 10 || st == 80 || st == 81 || st == 41 || st == 30 || st == 32) return YES;
    if (st == 51) {
        NSString *h5 = self.hf_config.dynamicParameter.rejectH5
            ?: [[HFLedgerFetch shared] hf_ledgerCache].dynamicParameter.rejectH5
            ?: @"";
        return [h5 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0;
    }
    return NO; // 100 / 20 / others: text only, no arrow / tap
}

- (void)hf_homeJumpOrderStatus:(NSInteger)orderStatus {
    HFDockBar *bar = nil;
    if ([self.tabBarController isKindOfClass:[HFDockBar class]]) {
        bar = (HFDockBar *)self.tabBarController;
    } else {
        UIViewController *p = self.parentViewController;
        while (p) {
            if ([p isKindOfClass:[HFDockBar class]]) {
                bar = (HFDockBar *)p;
                break;
            }
            p = p.parentViewController;
        }
    }
    if (!bar) return;
    [self.navigationController popToRootViewControllerAnimated:NO];
    [bar hf_dockSelectOrderStatus:orderStatus];
}

- (void)hf_homeTapAction:(UIButton *)sender {
    switch (sender.tag) {
        case 1: {
            HFMintPier *vc = [HFMintPier new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 2: {
            NSString *url = [HFVaultSeal kHrefContact];
            HFPaneBrowse *web = [[HFPaneBrowse alloc] initWithURLString:url title:@"Contact us"];
            web.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:web animated:YES];
            break;
        }
        case 3: {
            HFBeaconNest *vc = [HFBeaconNest new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default: break;
    }
}

- (void)hf_homeWithConfig:(void (^)(HFParcelConfig * _Nullable cfg))done {
    HFParcelConfig *cached = [[HFLedgerFetch shared] hf_ledgerCache] ?: self.hf_config;
    if (cached) {
        if (done) done(cached);
        return;
    }
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFLedgerFetch shared] hf_ledgerObtain:^(HFParcelConfig * _Nullable cfg) {
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (done) done(cfg ?: self.hf_config);
    }];
}

/// H5 KYC router `name` for `willExecuteStepNumber` (see packaged H5 routes).
- (nullable NSString *)hf_homeKycRoute:(NSString *)step {
    if ([step isEqualToString:@"1"]) return @"personal";
    if ([step isEqualToString:@"2"]) return @"work_questionnaire";
    if ([step isEqualToString:@"3"]) return @"urgent_contact";
    if ([step isEqualToString:@"4"]) return @"identity_liveness";
    return nil;
}

- (void)hf_homeOpenKYC {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pKycFourStatus]
                              signMap:@{}
                           nonSignMap:@{}
                            dataClass:[HFParcelKycStatus class]
                                   ok:^(HFParcelKycStatus *status) {
        __strong typeof(weakSelf) self = weakSelf;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        if (!self) return;
        NSString *step = [status hf_willExecuteStep] ?: @"";
        if ([step isEqualToString:@"-1"]) {
            [[HFOrbitHint shared] hf_orbitPulse:@"KYC already completed"];
            return;
        }
        NSString *kycId = [self hf_homeKycRoute:step];
        if (!kycId.length) {
            [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
            return;
        }
        [self hf_homeOpenH5:[HFVaultSeal kHrefKYC] title:nil extras:@{ @"kycId": kycId }];
    } fail:^(NSString * _Nullable msg, __unused NSString *code) {
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        [[HFOrbitHint shared] hf_orbitPulse:msg.length ? msg : @"the system is busy. Please try again in 2 minutes."];
    }];
}

- (void)hf_homeOpenH5:(NSString *)url title:(NSString *)title extras:(NSDictionary *)extras {
    NSString *trimmed = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (!trimmed.length) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Not available"];
        return;
    }
    NSLog(@"[HFDockLeafHome] open H5 url=%@ extras=%@", trimmed, extras);
    HFPaneBrowse *web = [[HFPaneBrowse alloc] initH5WithURLString:trimmed title:title extras:extras];
    web.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:web animated:YES];
}

@end
