#import <Foundation/Foundation.h>
#import <Contacts/Contacts.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HFTraceCode) {
    HFTraceCodeFirstOpen = 0,
    HFTraceCodeLaunch = 1,
    HFTraceCodePrivacy = 2,
    HFTraceCodeTerms = 3,
    HFTraceCodeSMS = 4,
    HFTraceCodeSignIn = 5,
    HFTraceCodeHomeApply = 7,
    HFTraceCodeCamOK = 11,
    HFTraceCodeCamNo = 12,
    HFTraceCodeLocOK = 15,
    HFTraceCodeLocNo = 16,
    HFTraceCodeIdfaOK = 17,
    HFTraceCodeIdfaNo = 18,
    HFTraceCodeBookOK = 19,
    HFTraceCodeBookNo = 20,
    HFTraceCodeBookPart = 198,
    HFTraceCodeRejectJump = 500,   // H5 only
    HFTraceCodeRejectClick = 501,  // H5 only
    HFTraceCodeRejectOpen = 502    // native thirdUrl
};

@interface HFTraceMark : NSObject
+ (instancetype)shared;
- (void)hf_trace:(HFTraceCode)code;
- (void)hf_trace:(HFTraceCode)code
         content:(nullable NSString *)content
              r1:(nullable NSString *)r1
              r2:(nullable NSString *)r2
              r3:(nullable NSString *)r3;

/// docs_phl/13 §2 — camera 11/12 (`permission_check` / `system_prompt`).
- (void)hf_traceCam:(BOOL)granted content:(nullable NSString *)content;
/// docs_phl/13 §2 — location 15/16.
- (void)hf_traceLoc:(BOOL)granted content:(nullable NSString *)content;
/// docs_phl/13 §2 — contacts 19/20/198; skips `.notDetermined`.
- (void)hf_traceBook:(CNAuthorizationStatus)status content:(nullable NSString *)content;
@end

NS_ASSUME_NONNULL_END
