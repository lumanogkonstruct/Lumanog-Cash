#import "HFTraceMark.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"

@implementation HFTraceMark

+ (instancetype)shared {
    static HFTraceMark *ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [HFTraceMark new];
    });
    return ins;
}

- (NSString *)hf_remark:(NSString *)s {
    if (![s isKindOfClass:[NSString class]]) return @"NULL";
    NSString *t = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return t.length ? t : @"NULL";
}

- (NSString *)hf_defaultContent:(HFTraceCode)code {
    switch (code) {
        case HFTraceCodeCamOK: return @"Camera permission granted";
        case HFTraceCodeCamNo: return @"Camera permission denied";
        case HFTraceCodeLocOK: return @"Location permission granted";
        case HFTraceCodeLocNo: return @"Location permission denied";
        case HFTraceCodeBookOK: return @"Contacts permission granted";
        case HFTraceCodeBookNo: return @"Contacts permission denied";
        case HFTraceCodeBookPart: return @"Contacts permission limited";
        case HFTraceCodeRejectOpen: return @"Reject external browser";
        default: return @"NULL";
    }
}

- (NSString *)hf_clipContent:(NSString *)content fallback:(NSString *)fallback {
    NSString *v = [content isKindOfClass:[NSString class]]
        ? [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";
    if (!v.length) v = fallback.length ? fallback : @"NULL";
    if (v.length > 1024) v = [v substringToIndex:1024];
    return v;
}

- (void)hf_trace:(HFTraceCode)code {
    [self hf_trace:code content:nil r1:nil r2:nil r3:nil];
}

- (void)hf_trace:(HFTraceCode)code content:(NSString *)content r1:(NSString *)r1 r2:(NSString *)r2 r3:(NSString *)r3 {
    NSString *eventContent = [self hf_clipContent:content fallback:[self hf_defaultContent:code]];
    NSDictionary *sign = @{
        @"eventCode": [NSString stringWithFormat:@"%ld", (long)code],
        @"eventContent": eventContent,
        @"remark1": [self hf_remark:r1],
        @"remark2": [self hf_remark:r2],
        @"remark3": [self hf_remark:r3]
    };
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pBuryRecord] signMap:sign nonSignMap:@{} ok:^(__unused id data) {
    } fail:^(__unused NSString *msg, __unused NSString *code) {
    }];
}

- (void)hf_traceCam:(BOOL)granted content:(NSString *)content {
    [self hf_trace:(granted ? HFTraceCodeCamOK : HFTraceCodeCamNo) content:content r1:nil r2:nil r3:nil];
}

- (void)hf_traceLoc:(BOOL)granted content:(NSString *)content {
    [self hf_trace:(granted ? HFTraceCodeLocOK : HFTraceCodeLocNo) content:content r1:nil r2:nil r3:nil];
}

- (void)hf_traceBook:(CNAuthorizationStatus)status content:(NSString *)content {
    switch (status) {
        case CNAuthorizationStatusAuthorized:
            [self hf_trace:HFTraceCodeBookOK content:content r1:nil r2:nil r3:nil];
            break;
        case CNAuthorizationStatusDenied:
        case CNAuthorizationStatusRestricted:
            [self hf_trace:HFTraceCodeBookNo content:content r1:nil r2:nil r3:nil];
            break;
        case CNAuthorizationStatusNotDetermined:
            break;
        default: {
            if (@available(iOS 18.0, *)) {
                if (status == CNAuthorizationStatusLimited) {
                    [self hf_trace:HFTraceCodeBookPart content:content r1:nil r2:nil r3:nil];
                    break;
                }
            }
            [self hf_trace:HFTraceCodeBookNo content:content r1:nil r2:nil r3:nil];
            break;
        }
    }
}

@end
