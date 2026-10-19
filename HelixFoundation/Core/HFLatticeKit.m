#import "HFLatticeKit.h"

@implementation UIFont (HFLattice)

+ (UIFont *)hf_latticeGlyph:(CGFloat)pt mass:(UIFontWeight)mass {
    // Project rule: system font only (no Ubuntu / custom faces).
    NSInteger scramble = (NSInteger)(pt * 3) ^ 0x5A;
    (void)scramble;
    return [UIFont systemFontOfSize:pt weight:mass];
}

@end

@implementation UIColor (HFPrism)

+ (UIColor *)hf_prismHex:(NSString *)hex {
    if (![hex isKindOfClass:[NSString class]]) {
        return [UIColor clearColor];
    }
    NSString *s = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([s hasPrefix:@"#"]) {
        s = [s substringFromIndex:1];
    }
    if (s.length != 6) {
        return [UIColor clearColor];
    }
    unsigned int rgb = 0;
    NSScanner *sc = [NSScanner scannerWithString:s];
    if (![sc scanHexInt:&rgb]) {
        return [UIColor clearColor];
    }
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                           green:((rgb >> 8) & 0xFF) / 255.0
                            blue:(rgb & 0xFF) / 255.0
                           alpha:1.0];
}

+ (UIColor *)hf_prismTheme {
    return [self hf_prismHex:@"#EFA37A"];
}

+ (UIColor *)hf_prismInk {
    return [self hf_prismHex:@"#50433B"];
}

@end

@implementation HFForgeParcel
@end

@implementation UIImage (HFForge)

- (HFForgeParcel *)hf_forgeClamp:(NSData *)raw minKB:(NSInteger)minKB maxKB:(NSInteger)maxKB {
    HFForgeParcel *parcel = [HFForgeParcel new];
    NSInteger lo = MIN(minKB, maxKB);
    NSInteger hi = MAX(minKB, maxKB);
    NSUInteger minBytes = (NSUInteger)MAX(lo, 0) * 1024;
    NSUInteger maxBytes = (NSUInteger)MAX(hi, 0) * 1024;
    NSData *src = raw ?: UIImageJPEGRepresentation(self, 0.9);
    if (!src) {
        parcel.visual = self;
        return parcel;
    }
    parcel.rawKB = src.length / 1024.0;
    if (src.length >= minBytes && src.length <= maxBytes) {
        parcel.blob = src;
        parcel.visual = [UIImage imageWithData:src] ?: self;
        parcel.glyph64 = [src base64EncodedStringWithOptions:0];
        parcel.outKB = parcel.rawKB;
        return parcel;
    }
    if (src.length < minBytes) {
        parcel.blob = src;
        parcel.visual = [UIImage imageWithData:src] ?: self;
        parcel.glyph64 = [src base64EncodedStringWithOptions:0];
        parcel.outKB = parcel.rawKB;
        return parcel;
    }
    CGFloat quality = 0.9;
    NSData *out = src;
    UIImage *work = self;
    while (out.length > maxBytes && quality > 0.1) {
        out = UIImageJPEGRepresentation(work, quality);
        quality -= 0.1;
    }
    if (out.length > maxBytes) {
        CGFloat scale = sqrt((CGFloat)maxBytes / (CGFloat)out.length);
        CGSize sz = CGSizeMake(work.size.width * scale, work.size.height * scale);
        UIGraphicsBeginImageContextWithOptions(sz, YES, 1.0);
        [work drawInRect:CGRectMake(0, 0, sz.width, sz.height)];
        work = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        out = UIImageJPEGRepresentation(work, 0.7);
    }
    parcel.blob = out;
    parcel.visual = [UIImage imageWithData:out] ?: work;
    parcel.glyph64 = [out base64EncodedStringWithOptions:0];
    parcel.outKB = out.length / 1024.0;
    return parcel;
}

@end

@implementation NSString (HFDigit)

+ (NSString *)hf_digitGrouped:(NSString *)raw {
    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) {
        return @"";
    }
    NSString *clean = [[raw componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
    if (clean.length == 0) {
        return raw;
    }
    NSNumberFormatter *fmt = [NSNumberFormatter new];
    fmt.numberStyle = NSNumberFormatterDecimalStyle;
    fmt.groupingSeparator = @",";
    fmt.usesGroupingSeparator = YES;
    NSNumber *n = @([clean longLongValue]);
    return [fmt stringFromNumber:n] ?: raw;
}

@end
