//
//  VideosTableViewController.m
//  VKVideo
//
//  Created by alexbutenko on 11/24/14.
//  Copyright (c) 2014 alexbutenko. All rights reserved.
//

#import "VideosTableViewController.h"
#import "VKSdk.h"
#import "VKVideo.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VideosTableViewController ()<VKSdkDelegate>

@property (nonatomic) NSArray *videos;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation VideosTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicatorView.center = self.view.center;
    self.activityIndicatorView.color = [UIColor blackColor];
    self.activityIndicatorView.hidesWhenStopped = YES;
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.activityIndicatorView];
    
    [VKSdk initializeWithDelegate:self andAppId:@"3974615"];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    if ([VKSdk wakeUpSession]) {
        [self loadVideos];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![VKSdk wakeUpSession]) {
        [self authorize];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadVideos {
    __weak typeof(self) weakSelf = self;
    
    [self.activityIndicatorView startAnimating];
    
    VKRequest *request = [VKRequest requestWithMethod:@"video.get"
                                       andParameters:@{VK_API_EXTENDED : @(1), VK_API_COUNT : @(100)}
                                       andHttpMethod:@"GET"];
    
    [request executeWithResultBlock:^(VKResponse *response) {
        
        [self.activityIndicatorView stopAnimating];
        weakSelf.videos = [VKVideo videosWithArrayOfInfos:response.json[@"items"]];
        [weakSelf.tableView reloadData];
        weakSelf.tableView.contentOffset = (CGPoint){0.0, -self.tableView.contentInset.top};

    } errorBlock:^(NSError *error) {
        NSLog(@"Error: %@", error);
        [self.activityIndicatorView stopAnimating];
    }];
}

- (void)authorize {
    [VKSdk authorize:@[VK_PER_VIDEO] revokeAccess:YES];
}

#pragma mark - VKSdkDelegate

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {
    VKCaptchaViewController *vc = [VKCaptchaViewController captchaControllerWithError:captchaError];
    [vc presentIn:self];
}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken {
    [self authorize];
}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken {
    [self loadVideos];
}

- (void)vkSdkAcceptedUserToken:(VKAccessToken *)token {
    [self loadVideos];
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller {
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError {
    [[[UIAlertView alloc] initWithTitle:nil message:@"Access denied" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.videos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kCellIdentifier = @"ListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    VKVideo *video = self.videos[indexPath.row];
    cell.textLabel.text = video.videoTitle;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VKVideo *video = self.videos[indexPath.row];
    
    [video loadVideoURLWithCompletionHandler:^(NSURL *videoURL) {
        MPMoviePlayerViewController *mpvc = [[MPMoviePlayerViewController alloc] init];
        mpvc.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
        mpvc.moviePlayer.contentURL = videoURL;

        // Remove the movie player view controller from the "playback did finish" notification observers
        [[NSNotificationCenter defaultCenter] removeObserver:mpvc  name:MPMoviePlayerPlaybackDidFinishNotification object:mpvc.moviePlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(videoFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:mpvc.moviePlayer];

        [self presentMoviePlayerViewControllerAnimated:mpvc];
    }];
}

- (void)videoFinished:(NSNotification*)aNotification {
    NSDictionary *notificationUserInfo = [aNotification userInfo];
    NSNumber *resultValue = [notificationUserInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    MPMovieFinishReason reason = [resultValue intValue];
    
    if (reason == MPMovieFinishReasonPlaybackError) {
        NSError *mediaPlayerError = [notificationUserInfo objectForKey:@"error"];
        if (mediaPlayerError) {
            NSLog(@"playback failed with error description: %@", [mediaPlayerError localizedDescription]);
        } else {
            NSLog(@"playback failed without any given reason");
        }
    } else {
        [self dismissMoviePlayerViewControllerAnimated];
    }
}

@end
