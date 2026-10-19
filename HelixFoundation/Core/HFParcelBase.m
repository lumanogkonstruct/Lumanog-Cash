#import "HFParcelBase.h"

@implementation HFParcelBase

+ (NSDictionary *)modelCustomPropertyMapper {

    return @{
        @"resultMsg": @"on",
        @"data": @"trick",
        @"timestamp": @"footstep",
    };
}

- (BOOL)hf_parcelAligned {
    return self.resultCode == 200 || [self.resultCodeText isEqualToString:@"200"];
}

/// Normalize resultCode from number / string inside Model (no caller-side dict dig).
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    // JSON keys are obfuscated (mapper targets); read raw dict keys.
    id raw = dic[@"respond"];
    if (!raw) raw = dic[@"resultCode"]; // fallback if backend not yet obfuscated
    if ([raw isKindOfClass:[NSNumber class]]) {
        self.resultCode = [(NSNumber *)raw integerValue];
        self.resultCodeText = [(NSNumber *)raw stringValue];
    } else if ([raw isKindOfClass:[NSString class]]) {
        NSString *s = (NSString *)raw;
        self.resultCodeText = s;
        self.resultCode = s.integerValue;
    } else {
        self.resultCodeText = self.resultCodeText.length ? self.resultCodeText : @"0";
    }
    id msg = dic[@"on"];
    if (!msg) msg = dic[@"resultMsg"];
    if (![msg isKindOfClass:[NSString class]] && msg != nil) {
        self.resultMsg = [NSString stringWithFormat:@"%@", msg];
    } else if ([msg isKindOfClass:[NSString class]]) {
        self.resultMsg = (NSString *)msg;
    }
    return YES;
}

@end
