//
//  RIGGitHelper.h
//  Reveal-In-GitHub
//
//  Created by lzw on 15/10/31.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RIGGitRepo : NSObject

@property (nonatomic, copy, readonly) NSString *localPath;

- (instancetype)initWithDocumentURL:(NSURL *)documentURL;

- (BOOL)isValid;

- (NSString *)latestCommitHash;
- (NSString *)filenameWithPathInCommit:(NSString *)commitHash;

- (NSString *)remoteRepoUrl;

@end
