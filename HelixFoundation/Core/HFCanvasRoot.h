#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^HFCanvasBackBlock)(void);

@interface HFCanvasRoot : UIViewController

@property (nonatomic, strong, nullable) UIImage *hf_canvasImage;
@property (nonatomic, strong, nullable) UIColor *hf_canvasTint;
@property (nonatomic, copy, nullable) HFCanvasBackBlock hf_onBackGate;
@property (nonatomic, copy, nullable) NSString *hf_navTitle;

- (void)hf_applyCanvas;
- (void)hf_wireBackItem;

@end

NS_ASSUME_NONNULL_END
