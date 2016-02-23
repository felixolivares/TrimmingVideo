//
//  RecordingVideoViewController.m
//  TrimmingVideo
//
//  Created by Jose Felix Olivares Estrada on 2/21/16.
//  Copyright © 2016 Jose Felix Olivares Estrada. All rights reserved.
//

#import "RecordingVideoViewController.h"
#import "VideoViewController.h"
#import "ViewController.h"
#import "ViewUtils.h"


@interface RecordingVideoViewController ()
@property (strong, nonatomic) LLSimpleCamera *camera;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UILabel *orientationLabel;
@property (strong, nonatomic) UIView *orientationContainer;
@property (strong, nonatomic) UIView *orientationBackground;
@property (strong, nonatomic) UIButton *snapButton;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UILabel *timerLabel;
@property (strong, nonatomic) UIView *timerBackground;
@property (strong, nonatomic) UIView *timerContainer;
@property (strong, nonatomic) UIView *recordingDot;

@property (readwrite, assign) int secondsLeft;
@property (readwrite, assign) BOOL isShowingLandscapeView;
@property (readwrite, assign) BOOL previousOrientation;

@end

@implementation RecordingVideoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self registerAllNotification];
    
    //Number of seconds available for video
    self.secondsLeft = 170;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    // ----- initialize camera -------- //
    
    // create camera vc
    self.camera = [[LLSimpleCamera alloc] initWithQuality:AVCaptureSessionPresetHigh
                                                 position:LLCameraPositionRear
                                             videoEnabled:YES];
    
    // attach to a view controller
    [self.camera attachToViewController:self withFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    
    // read: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
    // you probably will want to set this to YES, if you are going view the image outside iOS.
    self.camera.fixOrientationAfterCapture = YES;
    
    // take the required actions on a device change
    __weak typeof(self) weakSelf = self;
    [self.camera setOnDeviceChange:^(LLSimpleCamera *camera, AVCaptureDevice * device) {
        
        NSLog(@"Device changed.");
        
        // device changed, check if flash is available
        if([camera isFlashAvailable]) {
            weakSelf.flashButton.hidden = NO;
            
            if(camera.flash == LLCameraFlashOff) {
                weakSelf.flashButton.selected = NO;
            }
            else {
                weakSelf.flashButton.selected = YES;
            }
        }
        else {
            weakSelf.flashButton.hidden = YES;
        }
    }];
    
    [self.camera setOnError:^(LLSimpleCamera *camera, NSError *error) {
        NSLog(@"Camera error: %@", error);
        
        if([error.domain isEqualToString:LLSimpleCameraErrorDomain]) {
            if(error.code == LLSimpleCameraErrorCodeCameraPermission ||
               error.code == LLSimpleCameraErrorCodeMicrophonePermission) {
                
                if(weakSelf.errorLabel) {
                    [weakSelf.errorLabel removeFromSuperview];
                }
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.text = @"We need permission for the camera.\nPlease go to your settings.";
                label.numberOfLines = 2;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13.0f];
                label.textColor = [UIColor whiteColor];
                label.textAlignment = NSTextAlignmentCenter;
                [label sizeToFit];
                label.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                weakSelf.errorLabel = label;
                [weakSelf.view addSubview:weakSelf.errorLabel];
            }
        }
    }];
    
    // ----- camera buttons -------- //
    
    // snap button to capture image
    self.snapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.snapButton.frame = CGRectMake(0, 0, 70.0f, 70.0f);
    self.snapButton.clipsToBounds = YES;
    self.snapButton.layer.cornerRadius = self.snapButton.width / 2.0f;
    self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.snapButton.layer.borderWidth = 2.0f;
    self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.snapButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.snapButton.layer.shouldRasterize = YES;
    [self.snapButton addTarget:self action:@selector(snapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.snapButton.alpha = 0;
    [self.view addSubview:self.snapButton];
    
    // button to toggle flash
    self.flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.flashButton.frame = CGRectMake(0, 0, 16.0f + 20.0f, 24.0f + 20.0f);
    self.flashButton.tintColor = [UIColor whiteColor];
    [self.flashButton setImage:[UIImage imageNamed:@"camera-flash.png"] forState:UIControlStateNormal];
    self.flashButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.flashButton];
    
    if([LLSimpleCamera isFrontCameraAvailable] && [LLSimpleCamera isRearCameraAvailable]) {
        // button to toggle camera positions
        self.switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.switchButton.frame = CGRectMake(0, 0, 29.0f + 20.0f, 22.0f + 20.0f);
        self.switchButton.tintColor = [UIColor whiteColor];
        [self.switchButton setImage:[UIImage imageNamed:@"camera-switch.png"] forState:UIControlStateNormal];
        self.switchButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
        [self.switchButton addTarget:self action:@selector(switchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//        [self.view addSubview:self.switchButton];
    }
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Picture",@"Video"]];
    self.segmentedControl.frame = CGRectMake(12.0f, screenRect.size.height - 67.0f, 120.0f, 32.0f);
    self.segmentedControl.selectedSegmentIndex = 0;
    self.segmentedControl.tintColor = [UIColor whiteColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
//    [self.view addSubview:self.segmentedControl];
    
    self.orientationContainer = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 240, 42)];
    self.orientationContainer.layer.cornerRadius = 10;
    self.orientationContainer.backgroundColor = [UIColor clearColor];
    self.orientationContainer.alpha = 0;
    [self.view addSubview:self.orientationContainer];
    
    self.orientationBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 240, 42)];
    self.orientationBackground.layer.cornerRadius = 10;
    self.orientationBackground.backgroundColor = [UIColor blackColor];
    self.orientationBackground.alpha = 0.7;
    self.orientationBackground.center = self.orientationContainer.contentCenter;
    [self.orientationContainer addSubview:self.orientationBackground];
    
    self.orientationLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 240, 21)];
    self.orientationLabel.center = self.orientationContainer.contentCenter;
    self.orientationLabel.text = @"Please turn device into Landscape mode";
    self.orientationLabel.textColor = [UIColor whiteColor];
    [self.orientationLabel setFont:[UIFont fontWithName:@"Helvetica" size:11]];
    self.orientationLabel.textAlignment = NSTextAlignmentCenter;
    [self.orientationContainer addSubview:self.orientationLabel];
    
    self.timerContainer = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 50, 30)];
    self.timerContainer.backgroundColor = [UIColor clearColor];
    self.timerContainer.alpha = 0;
    [self.view addSubview:self.timerContainer];
    
    self.timerBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 60, 30)];
    self.timerBackground.layer.cornerRadius = 5;
    self.timerBackground.backgroundColor = [UIColor blackColor];
    self.timerBackground.alpha = 0.7;
    self.timerBackground.center = self.timerContainer.contentCenter;
    [self.timerContainer addSubview:self.timerBackground];
    
    self.timerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 50, 21)];
    self.timerLabel.center = self.timerContainer.contentCenter;
    self.timerLabel.left = -10.0f;
    self.timerLabel.textColor = [UIColor whiteColor];
    [self.timerLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
    self.timerLabel.textAlignment = NSTextAlignmentRight;
    [self.timerContainer addSubview:self.timerLabel];
    
    self.recordingDot = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 15, 15)];
    self.recordingDot.center = self.timerContainer.contentCenter;
    self.recordingDot.left = 1.0f;
    self.recordingDot.layer.cornerRadius = self.recordingDot.width / 2.0f;
    self.recordingDot.backgroundColor = [UIColor redColor];
    self.recordingDot.alpha = 0;
    [self.timerContainer addSubview:self.recordingDot];
    
    if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation))
    {
        NSLog(@"Portrait orientation at first");
        [self.view bringSubviewToFront:self.orientationContainer];
        [UIView animateWithDuration:0.2 animations:^{
            self.orientationContainer.alpha = 1;
            self.snapButton.alpha = 0;
            self.timerContainer.alpha = 0;
        }];
    }else{
        NSLog(@"Landscape orientation at first");
        [UIView animateWithDuration:0.2 animations:^{
            self.orientationContainer.alpha = 0;
            self.snapButton.alpha = 1;
            self.timerContainer.alpha = 1;
        }];
    }
    [self setCountdown];
}

-(void)setCountdown{
    int minutes, seconds;
    minutes = (self.secondsLeft % 3600) / 60;
    seconds = (self.secondsLeft %3600) % 60;
    self.timerLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    NSLog(@"%02d:%02d", minutes, seconds);
}

-(void) updateCountdown {
    int minutes, seconds;
    [UIView animateWithDuration:0.5 animations:^{
        self.recordingDot.alpha = 0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            self.recordingDot.alpha = 1;
        }];
    }];
    
    self.secondsLeft--;
    minutes = (self.secondsLeft % 3600) / 60;
    seconds = (self.secondsLeft %3600) % 60;
    self.timerLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    NSLog(@"%02d:%02d", minutes, seconds);
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)control
{
    NSLog(@"Segment value changed!");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // start the camera
    [self.camera start];
}

/* camera button methods */

- (void)switchButtonPressed:(UIButton *)button
{
    [self.camera togglePosition];
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)flashButtonPressed:(UIButton *)button
{
    if(self.camera.flash == LLCameraFlashOff) {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOn];
        if(done) {
            self.flashButton.selected = YES;
            self.flashButton.tintColor = [UIColor yellowColor];
        }
    }
    else {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOff];
        if(done) {
            self.flashButton.selected = NO;
            self.flashButton.tintColor = [UIColor whiteColor];
        }
    }
}

- (void)snapButtonPressed:(UIButton *)button
{
    
    if(!self.camera.isRecording) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target:self selector:@selector(updateCountdown) userInfo:nil repeats: YES];
        self.segmentedControl.hidden = YES;
        self.flashButton.hidden = YES;
        self.switchButton.hidden = YES;
        [UIView animateWithDuration:0.1 animations:^{
            self.timerLabel.left = 2.0f;
        } completion:^(BOOL finished) {
            self.recordingDot.alpha = 1;
        }];
        
        self.snapButton.layer.borderColor = [UIColor redColor].CGColor;
        self.snapButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        
        // start recording
        NSURL *outputURL = [[[self applicationDocumentsDirectory]
                             URLByAppendingPathComponent:@"test1"] URLByAppendingPathExtension:@"mp4"];
        [self.camera startRecordingWithOutputUrl:outputURL];
        
    } else {
        [self.timer invalidate];
        [self setCountdown];
        self.segmentedControl.hidden = YES;
        self.flashButton.hidden = NO;
        self.switchButton.hidden = NO;
        self.recordingDot.alpha  = 0;
        
        self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        
        [self.camera stopRecording:^(LLSimpleCamera *camera, NSURL *outputFileUrl, NSError *error) {
//            VideoViewController *vc = [[VideoViewController alloc] initWithVideoUrl:outputFileUrl];
//            [self.navigationController pushViewController:vc animated:YES];
//            ViewController *vc = [[ViewController alloc]initWithVideoUrl:outputFileUrl];
//            [self.navigationController pushViewController:vc animated:YES];
            [self performSegueWithIdentifier:@"toTrim" sender:outputFileUrl];
        }];
    }
}

/* other lifecycle methods */

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.camera.view.frame = self.view.contentBounds;
    
    self.snapButton.center = self.view.contentCenter;
    self.snapButton.right = self.view.width - 15.0f;
    
    self.flashButton.center = self.view.contentCenter;
    self.flashButton.top = 5.0f;
    
    self.switchButton.top = 5.0f;
    self.switchButton.right = self.view.width - 5.0f;
    
    self.segmentedControl.left = 12.0f;
    self.segmentedControl.bottom = self.view.height - 35.0f;
    
    self.orientationContainer.center = self.view.contentCenter;
    
    self.timerContainer.top = 5.0f;
    self.timerContainer.left = 12.0f;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) registerAllNotification{
    self.isShowingLandscapeView = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    self.previousOrientation    = NO;
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

#pragma mark -
#pragma mark Orientation Method
- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(deviceOrientation) &&
        !self.isShowingLandscapeView)
    {
        self.isShowingLandscapeView = YES;
    }
    else if (UIDeviceOrientationIsPortrait(deviceOrientation) &&
             self.isShowingLandscapeView)
    {
        self.isShowingLandscapeView = NO;
    }
    
    if (self.previousOrientation != self.isShowingLandscapeView){
        if (self.isShowingLandscapeView){
            NSLog(@"Orientation Change Occur: Landscape Mode");
        }
        else {
            NSLog(@"Orientation Change Occur: Portrait Mode");
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OrientationChange" object:nil];
        [self updateUI];
    }
    
    self.previousOrientation = self.isShowingLandscapeView;
}

-(void)updateUI{
    if (self.isShowingLandscapeView){
        //do the landscape tasks
        NSLog(@"Landscape");
        [UIView animateWithDuration:0.2 animations:^{
            self.orientationContainer.alpha = 0;
            self.snapButton.alpha = 1;
            self.timerContainer.alpha = 1;
        }];
    }
    else {
        //do the portrait tasks
        NSLog(@"Portrait");
        [UIView animateWithDuration:0.2 animations:^{
            self.orientationContainer.alpha = 1;
            self.snapButton.alpha = 0;
            self.timerContainer.alpha = 0;
        }];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"toTrim"]){
        ViewController *vc = [segue destinationViewController];
        NSURL *url = sender;
        NSLog(@"URL befor %@", url); 
        [vc setVideoUrl:url]; 
    }
}

@end
