#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <string.h>

typedef struct __attribute__((packed)) {
    char     riff[4];
    uint32_t chunkSize;
    char     wave[4];
    char     fmt[4];
    uint32_t fmtSize;
    uint16_t audioFormat;
    uint16_t channels;
    uint32_t sampleRate;
    uint32_t byteRate;
    uint16_t blockAlign;
    uint16_t bitsPerSample;
    char     data[4];
    uint32_t dataSize;
} TGBGWavHeader;

@interface TGBGKeeper : NSObject
+ (instancetype)shared;
- (void)observe;
@end

@implementation TGBGKeeper {
    AVAudioPlayer *_player;
    UIBackgroundTaskIdentifier _bgTask;
    NSTimer *_timer;
    BOOL _active;
}

+ (instancetype)shared {
    static TGBGKeeper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TGBGKeeper alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _bgTask = UIBackgroundTaskInvalid;
        _active = NO;
    }
    return self;
}

- (void)observe {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(appDidEnterBackground)
               name:UIApplicationDidEnterBackgroundNotification object:nil];
    [nc addObserver:self selector:@selector(appWillEnterForeground)
               name:UIApplicationWillEnterForegroundNotification object:nil];
    [nc addObserver:self selector:@selector(audioInterrupted:)
               name:AVAudioSessionInterruptionNotification object:nil];
    [nc addObserver:self selector:@selector(mediaServicesReset)
               name:AVAudioSessionMediaServicesWereResetNotification object:nil];
}

- (NSData *)silentWAV {
    const uint32_t sampleRate = 8000;
    const uint32_t dataSize = sampleRate * 2; // 1 second, 16-bit mono

    TGBGWavHeader h;
    memset(&h, 0, sizeof(h));
    memcpy(h.riff, "RIFF", 4);
    h.chunkSize = 36 + dataSize;
    memcpy(h.wave, "WAVE", 4);
    memcpy(h.fmt, "fmt ", 4);
    h.fmtSize = 16;
    h.audioFormat = 1;
    h.channels = 1;
    h.sampleRate = sampleRate;
    h.byteRate = sampleRate * 2;
    h.blockAlign = 2;
    h.bitsPerSample = 16;
    memcpy(h.data, "data", 4);
    h.dataSize = dataSize;

    NSMutableData *d = [NSMutableData dataWithBytes:&h length:sizeof(h)];
    [d increaseLengthBy:dataSize]; // zero-filled = silence
    return d;
}

- (void)configureSession {
    AVAudioSession *s = [AVAudioSession sharedInstance];
    NSString *cat = s.category;
    if (![cat isEqualToString:AVAudioSessionCategoryPlayback] &&
        ![cat isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        [s setCategory:AVAudioSessionCategoryPlayback
           withOptions:AVAudioSessionCategoryOptionMixWithOthers
                 error:nil];
    }
    [s setActive:YES error:nil];
}

- (void)ensurePlaying {
    if (!_active) return;
    [self configureSession];
    if (!_player) {
        NSError *err = nil;
        _player = [[AVAudioPlayer alloc] initWithData:[self silentWAV]
                                         fileTypeHint:AVFileTypeWAVE
                                                error:&err];
        if (!_player) return;
        _player.numberOfLoops = -1;
        [_player prepareToPlay];
    }
    if (!_player.isPlaying) {
        [_player play];
    }
}

- (void)endTask {
    if (_bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }
}

- (void)appDidEnterBackground {
    _active = YES;
    if (_bgTask == UIBackgroundTaskInvalid) {
        __weak TGBGKeeper *weakSelf = self;
        _bgTask = [[UIApplication sharedApplication]
            beginBackgroundTaskWithName:@"TGBGDownloaderKeepAlive"
                      expirationHandler:^{
            [weakSelf endTask];
        }];
    }
    [self ensurePlaying];
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                  target:self
                                                selector:@selector(tick)
                                                userInfo:nil
                                                 repeats:YES];
    }
}

- (void)appWillEnterForeground {
    _active = NO;
    [_timer invalidate];
    _timer = nil;
    [_player stop];
    _player = nil;
    [self endTask];
}

- (void)tick {
    [self ensurePlaying];
}

- (void)audioInterrupted:(NSNotification *)note {
    NSUInteger type = [note.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeEnded) {
        [self ensurePlaying];
    }
}

- (void)mediaServicesReset {
    _player = nil;
    [self ensurePlaying];
}

@end

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (![bundleID isEqualToString:@"ph.telegra.Telegraph"]) return;
        [[TGBGKeeper shared] observe];
    }
}
