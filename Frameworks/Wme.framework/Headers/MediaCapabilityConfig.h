#import <Foundation/Foundation.h>

#define DEFAULT_AUDIO_MAX_BANDWIDTH 64000
#define DEFAULT_VIDEO_MAX_BANDWIDTH 2000000
#define DEFAULT_SCREEN_SHARE_MAX_BANDWIDTH 4000000
#define DEFAULT_MULTISTREAM_TRACK_NUMBER 4
@interface MediaCapabilityConfig : NSObject

@property (nonatomic) UInt32 audioMaxRxBandwidth;
@property (nonatomic) UInt32 audioMaxTxBandwidth;
@property (nonatomic) UInt32 videoMaxRxBandwidth;
@property (nonatomic) UInt32 videoMaxTxBandwidth;
@property (nonatomic) UInt32 sharingMaxRxBandwidth;
@property (nonatomic) UInt32 sharingMaxTxBandwidth;

@property (nonatomic) UInt8 multiStreamTrackNumber;

@property (nonatomic) BOOL MQECallback;

@end
