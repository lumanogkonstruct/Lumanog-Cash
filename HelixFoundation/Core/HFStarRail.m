#import "HFStarRail.h"

static NSString * const kHFStarOn = @"two_icon_rate";
static NSString * const kHFStarOff = @"two_icon_rate_not";

@interface HFStarRail ()
@property (nonatomic, assign, readwrite) NSInteger hf_score;
@property (nonatomic, strong) UIStackView *hf_row;
@property (nonatomic, strong) NSArray<UIButton *> *hf_btns;
@property (nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *hf_sizeCs;
@property (nonatomic, strong, nullable) UIImage *hf_onImg;
@property (nonatomic, strong, nullable) UIImage *hf_offImg;
@end

@implementation HFStarRail

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _hf_starSide = 36;
        _hf_starGap = 12;
        _hf_score = 0;
        _hf_sizeCs = [NSMutableArray array];
        [self hf_starBuild];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _hf_starSide = 36;
        _hf_starGap = 12;
        _hf_score = 0;
        _hf_sizeCs = [NSMutableArray array];
        [self hf_starBuild];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.hf_starSide * 5 + self.hf_starGap * 4, self.hf_starSide);
}

- (void)setHf_starSide:(CGFloat)hf_starSide {
    if (fabs(_hf_starSide - hf_starSide) < 0.1) return;
    _hf_starSide = hf_starSide;
    for (NSLayoutConstraint *c in self.hf_sizeCs) c.constant = hf_starSide;
    [self invalidateIntrinsicContentSize];
}

- (void)setHf_starGap:(CGFloat)hf_starGap {
    if (fabs(_hf_starGap - hf_starGap) < 0.1) return;
    _hf_starGap = hf_starGap;
    self.hf_row.spacing = hf_starGap;
    [self invalidateIntrinsicContentSize];
}

- (void)hf_starBuild {
    self.hf_onImg = [UIImage imageNamed:kHFStarOn];
    self.hf_offImg = [UIImage imageNamed:kHFStarOff];

    self.hf_row = [UIStackView new];
    self.hf_row.axis = UILayoutConstraintAxisHorizontal;
    self.hf_row.alignment = UIStackViewAlignmentCenter;
    self.hf_row.distribution = UIStackViewDistributionFillEqually;
    self.hf_row.spacing = self.hf_starGap;
    self.hf_row.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.hf_row];
    [NSLayoutConstraint activateConstraints:@[
        [self.hf_row.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.hf_row.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.hf_row.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.hf_row.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    NSMutableArray *btns = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.tag = i + 1;
        b.adjustsImageWhenHighlighted = NO;
        b.translatesAutoresizingMaskIntoConstraints = NO;
        [b addTarget:self action:@selector(hf_starTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.hf_row addArrangedSubview:b];
        NSLayoutConstraint *w = [b.widthAnchor constraintEqualToConstant:self.hf_starSide];
        NSLayoutConstraint *h = [b.heightAnchor constraintEqualToConstant:self.hf_starSide];
        w.active = YES;
        h.active = YES;
        [self.hf_sizeCs addObject:w];
        [self.hf_sizeCs addObject:h];
        [btns addObject:b];
    }
    self.hf_btns = btns;
    [self hf_starPaint:NO];
}

- (void)hf_starTap:(UIButton *)sender {
    if (!self.userInteractionEnabled) return;
    [self hf_starSet:sender.tag animated:YES];
    if ([self.hf_delegate respondsToSelector:@selector(hf_starRail:didPick:)]) {
        [self.hf_delegate hf_starRail:self didPick:self.hf_score];
    }
    if (self.hf_onPick) self.hf_onPick(self.hf_score);
}

- (void)hf_starSet:(NSInteger)score animated:(BOOL)animated {
    NSInteger next = MAX(0, MIN(5, score));
    if (next == self.hf_score) return;
    self.hf_score = next;
    [self hf_starPaint:animated];
}

- (void)hf_starReset:(BOOL)animated {
    [self hf_starSet:0 animated:animated];
}

- (void)hf_starPaint:(BOOL)animated {
    void (^work)(void) = ^{
        for (UIButton *b in self.hf_btns) {
            BOOL on = b.tag <= self.hf_score;
            UIImage *img = on ? self.hf_onImg : self.hf_offImg;
            [b setImage:img forState:UIControlStateNormal];
        }
    };
    if (animated) {
        [UIView transitionWithView:self duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:work completion:nil];
    } else {
        work();
    }
}

@end
