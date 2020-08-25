#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define MAX_BANDWIDTH_90P 177000
#define MAX_BANDWIDTH_180P 384000
#define MAX_BANDWIDTH_360P 768000
#define MAX_BANDWIDTH_720P 2500000
#define MAX_BANDWIDTH_1080P 4000000

@interface MediaSCR : NSObject

@property (class, readonly) MediaSCR* p90;
@property (class, readonly) MediaSCR* p180;
@property (class, readonly) MediaSCR* p360;
@property (class, readonly) MediaSCR* p720;
@property (class, readonly) MediaSCR* p1080;

@property (nonatomic) unsigned int maxFs;
@property (nonatomic) unsigned int maxFps;
@property (nonatomic) unsigned int maxBr;
@property (nonatomic) unsigned int maxDpb;
@property (nonatomic) unsigned int maxMbps;
@property (nonatomic) unsigned int levelId;

+ (MediaSCR*)matchWithBandwidth:(unsigned int)bandwidth;

- (instancetype)initWithMaxFs:(unsigned int)fs
                   withMaxFPS:(unsigned int)fps
               withMaxBitrate:(unsigned int)br
                   withMaxDPB:(unsigned int)dpb
                  withMaxMBPS:(unsigned int)mbps;

@end

NS_ASSUME_NONNULL_END
