//
//  ViewController.m
//  TrimmingVideo
//
//  Created by Jose Felix Olivares Estrada on 2/17/16.
//  Copyright © 2016 Jose Felix Olivares Estrada. All rights reserved.
//

#import "ViewController.h"
#import "ICGVideoTrimmerView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "ViewUtils.h"
#import "triangleView.h"

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, ICGVideoTrimmerDelegate>

@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) int trimmedVideoSeconds;
@property (assign, nonatomic) float totalFileSize;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) NSTimer *playbackTimeCheckerTimer;
@property (assign, nonatomic) CGFloat videoPlaybackPosition;

@property (strong, nonatomic) ICGVideoTrimmerView *trimmerView;
@property (strong, nonatomic) UIView *trimmerContainer;
@property (strong, nonatomic) UIButton *trimButton;
@property (strong, nonatomic) UIButton *selectAsset;
@property (strong, nonatomic) UIView *videoPlayer;
@property (strong, nonatomic) UIView *videoLayer;
@property (strong, nonatomic) UISlider *slider;

@property (strong, nonatomic) UIView *infoContainer;
@property (strong, nonatomic) UIView *infoBackground;
@property (strong, nonatomic) UILabel *originalVideoTitle;
@property (strong, nonatomic) UILabel *originalVideoInfo;
@property (strong, nonatomic) UILabel *editedVideoTitle;
@property (strong, nonatomic) UILabel *editedVideoInfo;

@property (strong, nonatomic) UIView *navigationBar;
@property (strong, nonatomic) UILabel *navigationTitle;

@property (strong, nonatomic) UIView *playButton;
@property (strong, nonatomic) triangleView *triangle;

@property (strong, nonatomic) NSString *tempVideoPath;
@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (strong, nonatomic) AVAsset *asset;

@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat stopTime;
@property (assign, nonatomic) CGSize videoSize;



@property (assign, nonatomic) CGFloat firstTime;



@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIDevice currentDevice] setValue:
     [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
                                forKey:@"orientation"];

    self.tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpMov.mov"];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    self.view.backgroundColor = [UIColor colorWithRed:48.0/255 green:48.0/255 blue:48.0/255 alpha:1];
    
    self.navigationBar = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, 64)];
    self.navigationBar.backgroundColor = [UIColor colorWithRed:40.0/255 green:121.0/255 blue:254.0/254 alpha:1];
    [self.view addSubview:self.navigationBar];
    
    self.navigationTitle = [[UILabel alloc]initWithFrame:CGRectMake(60, 30, 150, 21)];
    self.navigationTitle.text = @"Edit Video";
    self.navigationTitle.textColor = [UIColor whiteColor];
    [self.navigationBar addSubview:self.navigationTitle];
    
    self.videoPlayer = [[UIView alloc]initWithFrame:CGRectMake(5, self.navigationBar.frame.origin.y + self.navigationBar.frame.size.height + 15, screenWidth - 10, 225)];
    self.videoLayer = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.videoPlayer.frame.size.width, self.videoPlayer.frame.size.height)];
    self.videoPlayer.backgroundColor = [UIColor colorWithRed:48.0/255 green:48.0/255 blue:48.0/255 alpha:1];
    self.videoLayer.backgroundColor = [UIColor clearColor];
    [self.videoPlayer addSubview:self.videoLayer];
    
    self.playButton = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.playButton.center = self.videoPlayer.contentCenter;
    self.playButton.clipsToBounds = YES;
    self.playButton.layer.cornerRadius = self.playButton.width / 2.0f;
    self.playButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.playButton.layer.borderWidth = 2.0f;
    self.playButton.backgroundColor = [UIColor clearColor];
    self.playButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.playButton.layer.shouldRasterize = YES;
    self.playButton.alpha = 0;
    [self.videoPlayer addSubview:self.playButton];
    
    self.triangle = [[triangleView alloc]initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.triangle.backgroundColor = [UIColor clearColor];
    self.triangle.center = self.playButton.contentCenter;
    self.triangle.left = 13.0f;
    [self.playButton addSubview:self.triangle];
    
    self.slider = [[UISlider alloc]initWithFrame:CGRectMake(15, self.videoPlayer.frame.origin.y + self.videoPlayer.frame.size.height + 30, screenWidth - 30, 8)];
    [self.slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [self.slider setBackgroundColor:[UIColor clearColor]];
    self.slider.minimumValue = 0.0;
    self.slider.maximumValue = 50.0;
    self.slider.continuous = YES;
    self.slider.value = 0;
    self.slider.hidden = YES;
    [self.slider setMinimumTrackTintColor:[UIColor whiteColor]];
    [self.view addSubview:self.slider];
    
    self.trimmerContainer = [[UIView alloc]initWithFrame:CGRectMake(0, self.slider.frame.origin.y + self.slider.frame.size.height + 30, screenWidth, 40)];
    self.trimmerContainer.backgroundColor = [UIColor clearColor];
    self.trimmerContainer.left = 15.0f;
    
    
    self.trimmerView = [[ICGVideoTrimmerView alloc]initWithFrame:CGRectMake(0, self.slider.frame.origin.y + self.slider.frame.size.height + 40, screenWidth, 40)];
//    self.trimmerView.center = self.trimmerContainer.contentCenter;
    self.trimmerView.backgroundColor = [UIColor colorWithRed:48.0/255 green:48.0/255 blue:48.0/255 alpha:1];
//    [self.trimmerContainer addSubview:self.trimmerView];
    
    self.trimButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.trimButton.top = 30.0f;
    self.trimButton.right = self.navigationBar.width - 15.0f;
    [self.trimButton setTitle:@">" forState:UIControlStateNormal];
    [self.trimButton setHidden:YES];
    [self.trimButton addTarget:self action:@selector(jumpTo) forControlEvents:UIControlEventTouchUpInside];
    
    self.selectAsset = [[UIButton alloc]initWithFrame:CGRectMake((screenWidth - 154)/2, 40, 154, 30)];
    [self.selectAsset setTitle:@"Select Asset" forState:UIControlStateNormal];
    [self.selectAsset addTarget:self action:@selector(selectedAsset) forControlEvents:UIControlEventTouchUpInside];
    self.firstTime = 1.0;
    
    self.infoContainer = [[UIView alloc]initWithFrame:CGRectMake(15, self.trimmerContainer.frame.origin.y + self.trimmerContainer.frame.size.height + 30, screenWidth - 30, 120)];
    self.infoContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.infoContainer];
    
    self.infoBackground = [[UIView alloc]initWithFrame:CGRectMake(self.infoContainer.frame.origin.x, self.infoContainer.frame.origin.y, self.infoContainer.frame.size.width, self.infoContainer.frame.size.height)];
    self.infoBackground.center = self.infoContainer.contentCenter;
    self.infoBackground.backgroundColor = [UIColor colorWithRed:68.0/255 green:68.0/255 blue:68.0/255 alpha:1];
    [self.infoContainer addSubview:self.infoBackground];
    
    self.originalVideoTitle = [[UILabel alloc]initWithFrame:CGRectMake(10, 5, 100, 21)];
    self.originalVideoTitle.text = @"Original Video";
    [self.originalVideoTitle setFont:[UIFont fontWithName:@"Helvetica-Bold" size:13.0f]];
    self.originalVideoTitle.textColor = [UIColor whiteColor];
    [self.infoContainer addSubview:self.originalVideoTitle];
    
    self.originalVideoInfo = [[UILabel alloc]initWithFrame:CGRectMake(10, self.originalVideoTitle.frame.origin.y + self.originalVideoTitle.frame.size.height + 2, self.infoContainer.frame.size.width - 20, 21)];
    [self.originalVideoInfo setFont:[UIFont fontWithName:@"Helvetica" size:13.0f]];
    self.originalVideoInfo.textColor = [UIColor colorWithRed:229.0/255 green:229.0/255 blue:229.0/255 alpha:1];
    [self.infoContainer addSubview:self.originalVideoInfo];
    
    self.editedVideoTitle = [[UILabel alloc]initWithFrame:CGRectMake(10, self.originalVideoInfo.frame.origin.y + self.originalVideoInfo.frame.size.height + 10, 100, 21)];
    self.editedVideoTitle.text = @"Edited Video";
    [self.editedVideoTitle setFont:[UIFont fontWithName:@"Helvetica-Bold" size:13.0f]];
    self.editedVideoTitle.textColor = [UIColor whiteColor];
    [self.infoContainer addSubview:self.editedVideoTitle];
    
    self.editedVideoInfo = [[UILabel alloc]initWithFrame:CGRectMake(10, self.editedVideoTitle.frame.origin.y + self.editedVideoTitle.frame.size.height + 2, self.infoContainer.frame.size.width - 20, 21)];
    [self.editedVideoInfo setFont:[UIFont fontWithName:@"Helvetica" size:13.0f]];
    self.editedVideoInfo.textColor = [UIColor colorWithRed:229.0/255 green:229.0/255 blue:229.0/255 alpha:1];
    [self.infoContainer addSubview:self.editedVideoInfo];
    
    
    [self.view addSubview:self.videoPlayer];
    [self.view addSubview:self.trimmerView];
    [self.navigationBar addSubview:self.trimButton];
//    [self.view addSubview:self.selectAsset];
    
    [self loadVideo:self.videoUrl];
    
    
}

-(void)viewWillAppear:(BOOL)animated{
    [self.slider addTarget:self action:@selector(sliderDidEndSliding:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
}

- (void)sliderDidEndSliding:(NSNotification *)notification {
    //Slider did end sliding
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:[self.player.currentItem asset]];
    CGImageRef ref = [imageGenerator copyCGImageAtTime:self.player.currentItem.currentTime actualTime:nil error:nil];
    UIImage *viewImage = [UIImage imageWithCGImage:ref];
    
    UIImageView *screenShotView = [[UIImageView alloc]initWithFrame:CGRectMake(10, self.infoContainer.frame.origin.y + self.infoContainer.frame.size.height + 10, 100, 56)];
    //    screenShotView.image = [UIImage imageNamed:@"brown"];
    screenShotView.image = viewImage;
    [self.view addSubview:screenShotView];
}

-(void)sliderAction:(id)sender
{
    if (self.isPlaying) {
        [self.player pause];
        [self stopPlaybackTimeChecker];
    }
//    }else {
//        [self.player play];
//        [self startPlaybackTimeChecker];
//    }
//    self.isPlaying = !self.isPlaying;
    [self.trimmerView hideTracker:true];
    
    UISlider *slider = (UISlider*)sender;
    float value = slider.value;
    NSLog(@"%f", value);
    [self seekVideoToPos:value];
    
    //-- Do further actions
}

-(void)selectedAsset{
    UIImagePickerController *myImagePickerController = [[UIImagePickerController alloc] init];
    myImagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    myImagePickerController.mediaTypes =
    [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    myImagePickerController.delegate = self;
    myImagePickerController.editing = NO;
    [self presentViewController:myImagePickerController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ICGVideoTrimmerDelegate

- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime
{
    if (startTime != self.startTime) {
        //then it moved the left position, we should rearrange the bar
        [self seekVideoToPos:startTime];
    }
    self.startTime = startTime;
    self.stopTime = endTime;
    
    NSLog(@"Start time : %f", self.startTime);
    NSLog(@"End time : %f", self.stopTime);
    self.slider.minimumValue = self.startTime;
    self.slider.maximumValue = self.stopTime;
    
    self.trimmedVideoSeconds = (int)CMTimeGetSeconds(CMTimeMakeWithSeconds(self.stopTime - self.startTime, self.asset.duration.timescale));
    NSLog(@"trimmed video seconds %d", self.trimmedVideoSeconds);
    
    int totalVideoSeconds = (int)CMTimeGetSeconds(self.player.currentItem.asset.duration);
    
    float trimmedVideoSize = (self.trimmedVideoSeconds * self.totalFileSize) / totalVideoSeconds;
    NSLog(@"%.2f MB", trimmedVideoSize);
    
    self.editedVideoInfo.text = [NSString stringWithFormat:@"%d x %d, %@, %.2f MB", (int)self.videoSize.width, (int)self.videoSize.height, [self getDuration:(int)CMTimeGetSeconds(CMTimeMakeWithSeconds(self.stopTime - self.startTime, self.asset.duration.timescale))], trimmedVideoSize];
    
}

-(NSString*)getDuration:(int)secondsLeft{
    int minutes, seconds;
    minutes = (secondsLeft % 3600) / 60;
    seconds = (secondsLeft %3600) % 60;
//    self.timerLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    NSLog(@"%02d:%02d", minutes, seconds);
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
    [self loadVideo:url];
}

-(void)loadVideo:(NSURL *)url{
    self.asset = [AVAsset assetWithURL:url];
    
    self.videoSize = [[[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    NSLog(@"%f : %f", self.videoSize.width, self.videoSize.height);
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
    
    self.player = [AVPlayer playerWithPlayerItem:item];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [self.videoLayer.layer addSublayer:self.playerLayer];
    
    //File size
    NSData *fileSizeData = [NSData dataWithContentsOfURL:url];
    self.totalFileSize = (float)fileSizeData.length/1024.0f/1024.0f;
    
    self.originalVideoInfo.text = [NSString stringWithFormat:@"%d x %d, %@, %.2f MB", (int)self.videoSize.width, (int)self.videoSize.height, [self getDuration:(int)CMTimeGetSeconds(self.player.currentItem.asset.duration)], self.totalFileSize];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnVideoLayer:)];
    UITapGestureRecognizer *tapPlay = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnVideoLayer:)];
    [self.videoLayer addGestureRecognizer:tap];
    [self.playButton addGestureRecognizer:tapPlay];
    
    self.videoPlaybackPosition = 0;
    
    [self tapOnVideoLayer:tap];
    
    // set properties for trimmer view
    //    [self.trimmerView setThemeColor:[UIColor lightGrayColor]];
    [self.trimmerView setThemeColor:[UIColor colorWithRed:42.0/255 green:127.0/255 blue:255/255 alpha:1]];
    [self.trimmerView setAsset:self.asset];
    [self.trimmerView setShowsRulerView:NO];
    [self.trimmerView setTrackerColor:[UIColor cyanColor]];
    [self.trimmerView setDelegate:self];
    
    // important: reset subviews
    [self.trimmerView resetSubviews];
    
    [self.trimButton setHidden:NO];
    [self.slider setHidden:NO];
}


#pragma mark - Actions

- (void)deleteTempFile
{
    NSURL *url = [NSURL fileURLWithPath:self.tempVideoPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:url error:&err];
        NSLog(@"file deleted");
        if (err) {
            NSLog(@"file remove error, %@", err.localizedDescription );
        }
    } else {
        NSLog(@"no file by that name");
    }
}


- (IBAction)trimVideo:(id)sender
{
    [self deleteTempFile];
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.asset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:self.asset presetName:AVAssetExportPresetPassthrough];
        // Implementation continues.
        
        NSURL *furl = [NSURL fileURLWithPath:self.tempVideoPath];
        
        self.exportSession.outputURL = furl;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        CMTime start = CMTimeMakeWithSeconds(self.startTime, self.asset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(self.stopTime - self.startTime, self.asset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    
                    NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    
                    NSLog(@"Export canceled");
                    break;
                default:
                    NSLog(@"NONE");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSURL *movieUrl = [NSURL fileURLWithPath:self.tempVideoPath];
                        UISaveVideoAtPathToSavedPhotosAlbum([movieUrl relativePath], self,@selector(video:didFinishSavingWithError:contextInfo:), nil);
                    });
                    
                    break;
            }
        }];
        
    }
}

- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)viewDidLayoutSubviews
{
    self.playerLayer.frame = CGRectMake(0, 0, self.videoLayer.frame.size.width, self.videoLayer.frame.size.height);
}

- (void)tapOnVideoLayer:(UITapGestureRecognizer *)tap
{
    if (self.isPlaying) {
        self.playButton.alpha = 1;
        [self.player pause];
        [self stopPlaybackTimeChecker];
    }else {
        self.playButton.alpha = 0;
        [self.player play];
        [self startPlaybackTimeChecker];
    }
    self.isPlaying = !self.isPlaying;
    [self.trimmerView hideTracker:!self.isPlaying];
}

- (void)startPlaybackTimeChecker
{
    [self stopPlaybackTimeChecker];
    
    self.playbackTimeCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(onPlaybackTimeCheckerTimer) userInfo:nil repeats:YES];
}

- (void)stopPlaybackTimeChecker
{
    if (self.playbackTimeCheckerTimer) {
        [self.playbackTimeCheckerTimer invalidate];
        self.playbackTimeCheckerTimer = nil;
    }
}

#pragma mark - PlaybackTimeCheckerTimer

- (void)onPlaybackTimeCheckerTimer
{
    self.videoPlaybackPosition = CMTimeGetSeconds([self.player currentTime]);
    
    [self.trimmerView seekToTime:CMTimeGetSeconds([self.player currentTime])];
    
    if (self.videoPlaybackPosition >= self.stopTime) {
        self.videoPlaybackPosition = self.startTime;
        [self seekVideoToPos: self.startTime];
        [self.trimmerView seekToTime:self.startTime];
    }
}

- (void)seekVideoToPos:(CGFloat)pos
{
    self.videoPlaybackPosition = pos;
    CMTime time = CMTimeMakeWithSeconds(self.videoPlaybackPosition, self.player.currentTime.timescale);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

-(void)setVideoUrl:(NSURL *)videoUrl{
    _videoUrl = videoUrl;
    NSLog(@"url string after %@", _videoUrl);
    [self loadVideo:_videoUrl];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskPortrait;
    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    // Return the orientation you'd prefer - this is what it launches to. The
    // user can still rotate. You don't have to implement this method, in which
    // case it launches in the current orientation
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    if ([touch.view isDescendantOfView:self.videoPlayer]) {
//        return YES;
//    }
//    return YES;
//}

@end
