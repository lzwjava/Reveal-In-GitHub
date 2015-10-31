//
//  RIGGitHelper.m
//  Reveal-In-Github
//
//  Created by lzw on 15/10/31.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGGitRepo.h"
#import "RIGUtils.h"
#import <Cocoa/Cocoa.h>
#import "RIGSetting.h"

@interface RIGGitRepo()

@property (nonatomic, strong) NSURL *documentURL;
@property (nonatomic, strong) NSString *documentDirectoryPath;
@property (nonatomic, copy) NSString *localPath;

@end

@implementation RIGGitRepo

- (instancetype)initWithDocumentURL:(NSURL *)documentURL {
    if (self == [super init]) {
        _documentURL = documentURL;
        _documentDirectoryPath = [[documentURL URLByDeletingLastPathComponent] path];
        _localPath = [self gitLocalPath];
    }
    return self;
}

- (NSString *)filenameWithPathInCommit:(NSString *)commitHash {
    NSArray *args = @[@"show", @"--name-only", @"--pretty=format:", commitHash];
    NSString *files = [self outputGitWithArguments:args inPath:self.documentDirectoryPath];
    
    NSString *documentFilename = [self.documentURL lastPathComponent];
    NSString *filenameWithPathInCommit = nil;
    for (NSString *filenameWithPath in [files componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]])
    {
        if ([filenameWithPath hasSuffix:documentFilename])
        {
            filenameWithPathInCommit = [filenameWithPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            break;
        }
    }
    
    if (!filenameWithPathInCommit)
    {
        LZLog(@"Unable to find file in commit.");
        return nil;
    }
    
    return filenameWithPathInCommit;
}

- (NSString *)latestCommitHash {
    NSString *documentFullPath = [self.documentURL path];
    // Get last commit hash
    NSArray *args = @[@"log", @"-n1", @"--no-decorate", documentFullPath];
    NSString *rawLastCommitHash = [self outputGitWithArguments:args inPath:self.documentDirectoryPath];
    LZLog(@"GIT log: %@", rawLastCommitHash);
    NSArray *commitHashInfo = [rawLastCommitHash componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (commitHashInfo.count < 2)
    {
//        [self showMessage:@"Unable to find lastest commit."];
        return nil;
    }
    
    NSString *commitHash = [commitHashInfo objectAtIndex:1];
    return commitHash;
}

- (NSString *)gitLocalPath {
    NSURL *activeDocumentURL = self.documentURL;
    NSString *activeDocumentDirectoryPath = [[activeDocumentURL URLByDeletingLastPathComponent] path];
    NSArray *args = @[@"rev-parse", @"--show-toplevel"];
    NSString *rootPath = [self outputGitWithArguments:args inPath:activeDocumentDirectoryPath];
    return [rootPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// Performs a git command with given args in the given directory
- (NSString *)outputGitWithArguments:(NSArray *)args inPath:(NSString *)path
{
    if (path.length == 0)
    {
        LZLog(@"Invalid path for git working directory.");
        return nil;
    }
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/xcrun";
    task.currentDirectoryPath = path;
    task.arguments = [@[@"git", @"--no-pager"] arrayByAddingObjectsFromArray:args];
    task.standardOutput = [NSPipe pipe];
    NSFileHandle *file = [task.standardOutput fileHandleForReading];
    
    [task launch];
    
    // For some reason [task waitUntilExit]; does not return sometimes. Therefore this rather hackish solution:
    int count = 0;
    while (task.isRunning && (count < 10))
    {
        [NSThread sleepForTimeInterval:0.1];
        count++;
    }
    
    NSString *output = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    
    return output;
}

- (NSString *)remotePathFromRemoteURL:(NSString *)remotePath {
    // Check for SSH protocol
    NSRange begin = [remotePath rangeOfString:@"git@"];
    
    if (begin.location == NSNotFound)
    {
        // SSH protocol not found, check for GIT protocol
        begin = [remotePath rangeOfString:@"git://"];
    }
    if (begin.location == NSNotFound)
    {
        // HTTPS protocol check
        begin = [remotePath rangeOfString:@"https://"];
    }
    if (begin.location == NSNotFound)
    {
        // HTTP protocol check
        begin = [remotePath rangeOfString:@"http://"];
    }
    
    NSRange end = [remotePath rangeOfString:@".git (fetch)"];
    
    if (end.location == NSNotFound)
    {
        // Alternate remote url end
        end = [remotePath rangeOfString:@" (fetch)"];
    }
    
    if ((begin.location != NSNotFound) &&
        (end.location != NSNotFound))
    {
        NSUInteger githubURLBegin = begin.location + begin.length;
        NSUInteger githubURLLength = end.location - githubURLBegin;
        return [[remotePath
                 substringWithRange:NSMakeRange(githubURLBegin, githubURLLength)]
                stringByReplacingOccurrencesOfString:@":" withString:@"/"];
    } else {
        return nil;
    }
}

#pragma mark - Remote Repo

- (NSString *)remoteRepoUrl {
    NSString *defaultRepo = [[RIGSetting setting] defaultRepo];
    if (defaultRepo != nil) {
        return defaultRepo;
    } else {
        NSString *selectedRepo = [self getOrAskRemoteRepoUrl];
        [[RIGSetting setting] setDefaultRepo:selectedRepo];
        return selectedRepo;
    }
}

- (NSString *)getOrAskRemoteRepoUrl {
    NSString *rootPath = [self localPath];
    // Get Github username and repo name
    NSArray *args = @[@"remote", @"--verbose"];
    NSString *output = [self outputGitWithArguments:args inPath:rootPath];
    NSArray *remoteURLs = [output componentsSeparatedByString:@"\n"];
    
    NSMutableSet *remotePaths = [NSMutableSet set];
    
    for (NSString *remoteURL in remoteURLs)
    {
        NSString *remotePath = [self remotePathFromRemoteURL:remoteURL];
        if (remotePath) {
            [remotePaths addObject:remotePath];
        }
    }
    
    NSString *selectedRemotePath;
    if (remotePaths.count == 1) {
        selectedRemotePath = [remotePaths allObjects][0];
    } else if (remotePaths.count > 1) {
        NSArray *sortedRemotePaths = remotePaths.allObjects;
        
        // Ask the user what remote to use.
        // Attention: Due to NSRunAlert maximal three remotes are supported.
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSInformationalAlertStyle;
        alert.messageText = [NSString stringWithFormat:@"This repository has %ld remotes configured. Which one do you want to open?", remotePaths.count];
        [alert addButtonWithTitle:[sortedRemotePaths objectAtIndex:0]];
        [alert addButtonWithTitle:[sortedRemotePaths objectAtIndex:1]];
        [alert addButtonWithTitle:(sortedRemotePaths.count > 2 ? [sortedRemotePaths objectAtIndex:2] : nil)];
        
        NSModalResponse button = [alert runModal];
        if (button == NSAlertFirstButtonReturn) {
            selectedRemotePath = sortedRemotePaths[0];
        } else if (button == NSAlertSecondButtonReturn) {
            selectedRemotePath = sortedRemotePaths[1];
        } else if (button == NSAlertThirdButtonReturn) {
            selectedRemotePath = sortedRemotePaths[2];
        }
    }
    
    if (selectedRemotePath.length == 0)
    {
        LZLog(@"Unable to find github remote URL.");
        return nil;
    }
    
    NSString *fullUrl = [NSString stringWithFormat:@"https://%@", selectedRemotePath];
    
    return fullUrl;
}

- (BOOL)isValid {
    if (!self.localPath) {
        return NO;
    }
    return YES;
}

@end
