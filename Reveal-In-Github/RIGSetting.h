//
//  RIGSettingsManager.h
//  Reveal-In-Github
//
//  Created by lzw on 15/10/31.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RIGSetting : NSObject

+ (RIGSetting *)setting;
+ (RIGSetting *)settingForGitPath:(NSString *)gitPath;

@property (nonatomic, strong) NSArray *configs;
@property (nonatomic, strong) NSString *defaultRepo;;

+ (NSArray *)defaultConfigs;

@end
