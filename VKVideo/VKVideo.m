//
//  VKVideo.m
//  VKVideo
//
//  Created by alexbutenko on 11/24/14.
//  Copyright (c) 2014 alexbutenko. All rights reserved.
//

#import "VKVideo.h"

@implementation VKVideo

- (instancetype)initWithInfo:(NSDictionary *)videoInfo {
    self = [super init];
    
    if (self) {
        self.videoScriptURL = [NSURL URLWithString:videoInfo[@"player"]];
        self.videoTitle = videoInfo[@"title"];
    }
    
    return self;
}

+ (instancetype)videoWithInfo:(NSDictionary *)videoInfo {
    return [[[self class] alloc] initWithInfo:videoInfo];
}

+ (NSArray *)videosWithArrayOfInfos:(NSArray *)arrayOfVideoInfos {
    NSMutableArray *videos = [NSMutableArray new];
    for (NSDictionary *videoInfo in arrayOfVideoInfos) {
        [videos addObject:[self videoWithInfo:videoInfo]];
    }
    
    return videos;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ URL: %@", [super description], self.videoTitle, self.videoScriptURL];
}

static NSUInteger kVideoQualities[4] = {240, 360, 480, 720};

- (NSArray *)videoTagsForHTMLString:(NSString *)HTMLString {
    NSMutableArray *qualities = [NSMutableArray new];
    
    for (NSInteger i = 0; i < 4; i++) {
        
        NSString *tag = [NSString stringWithFormat:@"url%li", kVideoQualities[i]];
        
        if ([HTMLString rangeOfString:tag].location != NSNotFound) {
            [qualities addObject:tag];
        }
    }
    
    return qualities;
}

/**
 *  Load PHP script to parse direct video URLs
 *
 *  @return best available video quality URL
 */
- (void)loadVideoURLWithCompletionHandler:(completion_block_t)completionBlock {
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:self.videoScriptURL]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSString *HTMLString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                               NSArray *videoTags = [self videoTagsForHTMLString:HTMLString];
                               
                               NSScanner *scanner = [NSScanner scannerWithString:HTMLString];
                               NSString *videoURLString = nil;

                               while (![scanner isAtEnd]) {
                                   [scanner scanUpToString:[videoTags lastObject] intoString:NULL];
                                   [scanner setScanLocation:scanner.scanLocation + [[videoTags lastObject] length] + 1];
                                   
                                   if ([scanner scanUpToString:@"&amp;" intoString:&videoURLString]) {
                                       NSLog(@"videoURLString %@", videoURLString);
                                       completionBlock([NSURL URLWithString:videoURLString]);
                                       break;
                                   }
                               }
                           }
     ];
}


@end
