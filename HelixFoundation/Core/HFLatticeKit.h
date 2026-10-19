#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (HFLattice)
+ (UIFont *)hf_latticeGlyph:(CGFloat)pt mass:(UIFontWeight)mass;
@end

@interface UIColor (HFPrism)
+ (UIColor *)hf_prismHex:(NSString *)hex;
+ (UIColor *)hf_prismTheme;
/// Default body / label text color `#50433B`
+ (UIColor *)hf_prismInk;
@end

@interface HFForgeParcel : NSObject
@property (nonatomic, strong, nullable) UIImage *visual;
@property (nonatomic, strong, nullable) NSData *blob;
@property (nonatomic, copy, nullable) NSString *glyph64;
@property (nonatomic, assign) CGFloat rawKB;
@property (nonatomic, assign) CGFloat outKB;
@end

@interface UIImage (HFForge)
- (HFForgeParcel *)hf_forgeClamp:(NSData *)raw minKB:(NSInteger)minKB maxKB:(NSInteger)maxKB;
@end

@interface NSString (HFDigit)
+ (NSString *)hf_digitGrouped:(NSString *)raw;
@end

NS_ASSUME_NONNULL_END
