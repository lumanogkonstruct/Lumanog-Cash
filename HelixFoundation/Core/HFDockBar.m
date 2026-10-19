#import "HFDockBar.h"
#import "HFDockLeaf.h"
#import "HFLatticeKit.h"

@interface HFDockBar () <UITabBarControllerDelegate>
@property (nonatomic, strong) NSMutableSet<NSNumber *> *loaded;
@end

@implementation HFDockBar

+ (instancetype)hf_dockAssemble {
    HFDockBar *bar = [HFDockBar new];
    bar.loaded = [NSMutableSet set];
    bar.delegate = bar;

    UINavigationController *n0 = [UINavigationController new];
    UINavigationController *n1 = [UINavigationController new];
    UINavigationController *n2 = [UINavigationController new];

    n0.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home"
                                                  image:[[UIImage imageNamed:@"one_icon_home_not"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                          selectedImage:[[UIImage imageNamed:@"one_icon_home"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    n1.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Order"
                                                  image:[[UIImage imageNamed:@"one_icon_order_not"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                          selectedImage:[[UIImage imageNamed:@"one_icon_order"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    n2.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Me"
                                                  image:[[UIImage imageNamed:@"one_icon_me_not"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                          selectedImage:[[UIImage imageNamed:@"one_icon_me"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];

    bar.viewControllers = @[n0, n1, n2];

    UITabBarAppearance *app = [UITabBarAppearance new];
    [app configureWithOpaqueBackground];
    app.backgroundColor = UIColor.whiteColor;
    UIColor *normal = [UIColor hf_prismHex:@"#CACACA"];
    UIColor *sel = [UIColor hf_prismHex:@"#50433B"];
    UIFont *font = [UIFont hf_latticeGlyph:12 mass:UIFontWeightRegular];
    app.stackedLayoutAppearance.normal.titleTextAttributes = @{ NSForegroundColorAttributeName: normal, NSFontAttributeName: font };
    app.stackedLayoutAppearance.selected.titleTextAttributes = @{ NSForegroundColorAttributeName: sel, NSFontAttributeName: font };
    app.stackedLayoutAppearance.normal.iconColor = normal;
    app.stackedLayoutAppearance.selected.iconColor = sel;
    bar.tabBar.standardAppearance = app;
    if (@available(iOS 15.0, *)) {
        bar.tabBar.scrollEdgeAppearance = app;
    }
    bar.tabBar.tintColor = sel;
    bar.tabBar.unselectedItemTintColor = normal;

    [bar hf_dockLoadIndex:0];
    return bar;
}

- (void)hf_dockLoadIndex:(NSInteger)idx {
    if (idx < 0 || idx >= (NSInteger)self.viewControllers.count) return;
    if ([self.loaded containsObject:@(idx)]) return;
    UINavigationController *nav = (UINavigationController *)self.viewControllers[idx];
    if (![nav isKindOfClass:[UINavigationController class]]) return;
    UIViewController *root = nil;
    if (idx == 0) root = [HFDockLeafHome new];
    else if (idx == 1) root = [HFDockLeafOrder new];
    else root = [HFDockLeafMe new];
    nav.viewControllers = @[root];
    [self.loaded addObject:@(idx)];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    NSInteger idx = [tabBarController.viewControllers indexOfObject:viewController];
    [self hf_dockLoadIndex:idx];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    [UIView setAnimationsEnabled:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView setAnimationsEnabled:YES];
    });
    return YES;
}

- (void)hf_dockSelectOrderStatus:(NSInteger)orderStatus {
    [self hf_dockLoadIndex:1];
    UINavigationController *nav = (UINavigationController *)self.viewControllers[1];
    if (![nav isKindOfClass:[UINavigationController class]]) return;
    [nav popToRootViewControllerAnimated:NO];
    UIViewController *root = nav.viewControllers.firstObject;
    // Set filter BEFORE selectedIndex so first viewDidLoad/viewWillAppear keep the status.
    if ([root isKindOfClass:[HFDockLeafOrder class]]) {
        [(HFDockLeafOrder *)root hf_orderFocusStatus:orderStatus];
    }
    self.selectedIndex = 1;
    // Re-apply after tab switch (covers deferred view load / appear order).
    if ([root isKindOfClass:[HFDockLeafOrder class]]) {
        [(HFDockLeafOrder *)root hf_orderFocusStatus:orderStatus];
    }
}

@end
