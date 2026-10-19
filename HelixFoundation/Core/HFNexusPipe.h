#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HFNexusOK)(id _Nullable dataModel);
/// `code` = `resultCodeText` when biz response is non-200; nil on transport errors.
typedef void (^HFNexusFail)(NSString * _Nullable msg, NSString * _Nullable code);

@interface HFNexusPipe : NSObject

+ (instancetype)shared;

- (void)hf_pipeBoot:(void (^)(BOOL ready))done;

/// POST — `dataClass` maps response.data via YYModel; pass Nil to receive raw `data` Model field only when no typed class.
- (void)hf_pipePost:(NSString *)path
            signMap:(nullable NSDictionary *)signData
         nonSignMap:(nullable NSDictionary *)nonSignData
          dataClass:(nullable Class)dataClass
                 ok:(HFNexusOK)ok
               fail:(HFNexusFail)fail;

/// Convenience: dataClass = Nil
- (void)hf_pipePost:(NSString *)path
            signMap:(nullable NSDictionary *)signData
         nonSignMap:(nullable NSDictionary *)nonSignData
                 ok:(HFNexusOK)ok
               fail:(HFNexusFail)fail;

/// Full-body reply class (subclass of HFParcelBase with typed data). Preferred.
- (void)hf_pipePost:(NSString *)path
            signMap:(nullable NSDictionary *)signData
         nonSignMap:(nullable NSDictionary *)nonSignData
         replyClass:(Class)replyClass
                 ok:(void (^)(id reply))ok
               fail:(HFNexusFail)fail;

- (void)hf_pipeUpload:(NSString *)path
              signMap:(nullable NSDictionary *)signData
           nonSignMap:(nullable NSDictionary *)nonSignData
             fileData:(NSData *)fileData
             fileName:(NSString *)fileName
             mimeType:(NSString *)mimeType
             progress:(nullable void (^)(NSProgress *p))progress
            dataClass:(nullable Class)dataClass
                   ok:(HFNexusOK)ok
                 fail:(HFNexusFail)fail;

- (void)hf_pipeUpload:(NSString *)path
              signMap:(nullable NSDictionary *)signData
           nonSignMap:(nullable NSDictionary *)nonSignData
             fileData:(NSData *)fileData
             fileName:(NSString *)fileName
             mimeType:(NSString *)mimeType
             progress:(nullable void (^)(NSProgress *p))progress
                   ok:(HFNexusOK)ok
                 fail:(HFNexusFail)fail;

@end

NS_ASSUME_NONNULL_END
