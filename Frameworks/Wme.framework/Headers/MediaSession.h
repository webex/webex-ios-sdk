#import <Foundation/Foundation.h>
#import "MediaConstraint.h"
#import "FrameInfo.h"

typedef NS_ENUM(NSInteger, MediaSessionType) {
    MediaSessionTypeLocalAudio,
    MediaSessionTypeRemoteAudio,
    MediaSessionTypeLocalVideo,
    MediaSessionTypeRemoteVideo,
    MediaSessionTypeLocalScreenShare,
    MediaSessionTypeRemoteScreenShare,
    MediaSessionTypeAuxVideo,
    MediaSessionTypePreview
};

@interface MediaSession : NSObject

// SDP & constraint
@property (nonatomic) NSString *localSdpOffer;
@property (nonatomic) MediaConstraint *mediaConstraint;
// proximity
@property (nonatomic) BOOL proximityPreferred;

//camera & speaker
- (void)setDefaultCamera:(BOOL)useFront;
- (void)toggleCamera;
- (BOOL)isFrontCameraSelected;
- (void)setCamrea:(BOOL)frontCamera;

- (void)setDefaultAudioOutput:(BOOL)useSpeaker;
- (void)toggleSpeaker;
- (BOOL)isSpeakerSelected;
- (void)setSpeaker:(BOOL)useSpeaker;

// render view
- (void)addRenderView:(UIView *)renderView type:(MediaSessionType)type andVid:(int)vid;
- (void)addRenderView:(UIView *)renderView type:(MediaSessionType)type;
- (void)removeRenderView:(UIView *)renderView type:(MediaSessionType)type andVid:(int)vid;
- (void)removeRenderView:(UIView *)renderView type:(MediaSessionType)type;
- (void)removeAllRenderView:(MediaSessionType)type;
- (void)updateRenderView:(UIView *)renderView type:(MediaSessionType)type andVid:(int)vid;
- (void)updateRenderView:(UIView *)renderView type:(MediaSessionType)type;
- (UIView *)getRenderViewWithType:(MediaSessionType)type andVid:(int)vid;
- (UIView *)getRenderViewWithType:(MediaSessionType)type;
- (CGSize)getRenderViewSizeWithType:(MediaSessionType)type andVid:(int)vid;
- (CGSize)getRenderViewSizeWithType:(MediaSessionType)type;

// audio & video control
- (void)muteMedia:(MediaSessionType)type;
- (void)unmuteMedia:(MediaSessionType)type;
- (void)muteMedia:(MediaSessionType)type andVid:(int)vid;
- (void)unmuteMedia:(MediaSessionType)type andVid:(int)vid;

- (Boolean)getMediaMutedFromLocal:(MediaSessionType)type andVid:(int)vid;
- (Boolean)getMediaMutedFromRemote:(MediaSessionType)type andVid:(int)vid;
- (Boolean)getMediaMutedFromLocal:(MediaSessionType)type;
- (Boolean)getMediaMutedFromRemote:(MediaSessionType)type;

- (void)stopAudio;
- (void)startAudio;

// SDP
- (NSString*)createLocalSdpOffer;
- (void)receiveRemoteSdpAnswer:(NSString*)sdp;
- (void)updateSdpDirectionWithLocalView:(UIView *)localView remoteView:(UIView *)remoteView;
- (void)updateSdpDirectionWithScreenShare:(UIView *)screenShareView;

// Media Session life cycle
- (void)createMediaConnection;
- (void)connectToCloud;
- (void)disconnectFromCloud;

- (void)startVideoRenderViewWithType:(MediaSessionType)type;
- (void)stopVideoRenderViewWithType:(MediaSessionType)type removeRender:(BOOL)removeRender;

//screen share
- (void)joinScreenShare:(NSString *)shareId isSending:(BOOL)isSending;
- (void)leaveScreenShare:(NSString *)shareId isSending:(BOOL)isSending;
- (void)startLocalScreenShare;
- (void)stopLocalScreenShare;
- (void)onReceiveScreenBroadcastData:(FrameInfo)frameInfo frameData:(NSData *)frameData;

//multi stream
- (int)subscribeVideoTrack:(UIView *)renderView;
- (void)unsubscribeVideoTrack:(int)vid;
@end
