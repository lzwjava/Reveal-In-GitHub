//
//  RIGSettingWindowController.h
//  Reveal-In-Github
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RIGGitRepo.h"

@interface RIGSettingWindowController : NSWindowController

@property (nonatomic, strong) RIGGitRepo *gitRepo;

@end
