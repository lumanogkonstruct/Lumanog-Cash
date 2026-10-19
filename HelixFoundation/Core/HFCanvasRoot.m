#import "HFCanvasRoot.h"
#import "HFLatticeKit.h"

@interface HFCanvasRoot ()
@property (nonatomic, strong) UIImageView *hf_bgView;
@end

@implementation HFCanvasRoot

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = self.hf_canvasTint ?: [UIColor hf_prismHex:@"#F5EDE2"];
    [self hf_applyCanvas];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    if (self.navigationController.navigationBar) {
        UIColor *barTint = [UIColor hf_prismHex:@"#50433B"];
        UINavigationBarAppearance *app = [UINavigationBarAppearance new];
        [app configureWithOpaqueBackground];
        app.backgroundColor = barTint;
        app.shadowColor = UIColor.clearColor;
        app.titleTextAttributes = @{
            NSForegroundColorAttributeName: UIColor.whiteColor,
            NSFontAttributeName: [UIFont hf_latticeGlyph:17 mass:UIFontWeightMedium]
        };
        UINavigationBar *bar = self.navigationController.navigationBar;
        bar.standardAppearance = app;
        bar.scrollEdgeAppearance = app;
        bar.compactAppearance = app;
        bar.tintColor = UIColor.whiteColor;
        bar.barTintColor = barTint;
        bar.translucent = NO;
    }
    if (self.hf_navTitle.length) {
        self.title = self.hf_navTitle;
    }
    [self hf_wireBackItem];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)hf_applyCanvas {
    UIColor *plain = self.hf_canvasTint ?: [UIColor hf_prismHex:@"#F5EDE2"];
    if (self.hf_canvasImage) {
        if (!self.hf_bgView) {
            self.hf_bgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
            self.hf_bgView.contentMode = UIViewContentModeScaleAspectFill;
            self.hf_bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view insertSubview:self.hf_bgView atIndex:0];
        }
        self.hf_bgView.image = self.hf_canvasImage;
        self.hf_bgView.hidden = NO;
    } else {
        self.hf_bgView.hidden = YES;
        self.view.backgroundColor = plain;
    }
}

- (void)hf_wireBackItem {
    if (self.navigationController.viewControllers.count <= 1) return;
    UIImage *img = [UIImage imageNamed:@"one_icon_back"];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(hf_tapBack)];
    self.navigationItem.leftBarButtonItem = item;
}

- (void)hf_tapBack {
    if (self.hf_onBackGate) {
        if (!self.hf_onBackGate()) return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
