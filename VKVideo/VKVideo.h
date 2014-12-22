//
//  VKVideo.h
//  VKVideo
//
//  Created by alexbutenko on 11/24/14.
//  Copyright (c) 2014 alexbutenko. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^completion_block_t)(NSURL *videoURL);

@interface VKVideo : NSObject

@property (nonatomic) NSURL *videoScriptURL;
@property (nonatomic) NSString *videoTitle;

+ (NSArray *)videosWithArrayOfInfos:(NSArray *)arrayOfVideoInfos;

- (void)loadVideoURLWithCompletionHandler:(completion_block_t)completionBlock;

@end
