#import <Foundation/Foundation.h>

#define DEFAULT_AUDIO_MAX_BANDWIDTH 64000
#define DEFAULT_SCREEN_SHARE_MAX_BANDWIDTH 4000000
#define DEFAULT_MULTISTREAM_TRACK_NUMBER 4
@interface MediaCapabilityConfig : NSObject

#pragma mark - bandwidth
@property (nonatomic) UInt32 audioMaxRxBandwidth;
@property (nonatomic) UInt32 audioMaxTxBandwidth;
@property (nonatomic) UInt32 videoMaxRxBandwidth;
@property (nonatomic) UInt32 videoMaxTxBandwidth;
@property (nonatomic) UInt32 sharingMaxRxBandwidth;
@property (nonatomic) UInt32 sharingMaxTxBandwidth;

@property (nonatomic) UInt8 multiStreamTrackNumber;

#pragma mark - global
@property (nonatomic) NSString* deviceSettings;
@property (nonatomic) BOOL MQECallback;
@property (nonatomic) BOOL isICEEnabled;
@property (nonatomic) BOOL isMultiStreamEnabled;
@property (nonatomic) BOOL isQoSEnabled;
@property (nonatomic) unsigned int waitMsWhenNetworkBad;
@property (nonatomic) unsigned int waitMsWhenNetworkVideoOff;
@property (nonatomic) unsigned int waitMsWhenNetworkRecovered;
@property (nonatomic) float maxQosLossRatio;

#pragma mark - audio
@property (nonatomic) BOOL isASNOEnabled;
@property (nonatomic) BOOL isAGCEnabled;
@property (nonatomic) BOOL isAudioFECEnabled;
@property (nonatomic) BOOL isECEnabled;
@property (nonatomic) BOOL isNSEnabled;
@property (nonatomic) BOOL isVADEnabled;
@property (nonatomic) BOOL isBNREnabled;
@property (nonatomic) UInt8 bnrProfileMode;
@property (nonatomic) UInt8 mixingStreamNum;

#pragma mark - video
@property (nonatomic) BOOL isVideoFECEnabled;
@property (nonatomic) BOOL isHWAccelerationEncoderEnabled;
@property (nonatomic) BOOL isHWAccelerationDecoderEnabled;
@property (nonatomic) BOOL isAVCSimulcastEnabled;
@property (nonatomic) BOOL isDecoderMosaicEnabled;
@property (nonatomic) unsigned int maxPacketSize;
@property (nonatomic) unsigned int videoMaxTxFPS;
@property (nonatomic) BOOL isVideoReceiverBasedQosSupported;
@property (nonatomic) BOOL isVideoCHPEnabled;

@end
