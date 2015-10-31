//
//  RIGSettingsManager.m
//  Reveal-In-Github
//
//  Created by lzw on 15/10/31.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGSetting.h"
#import "RIGConfig.h"

#define kRIGDefaultRepo @"com.lzwjava.reveal-in-github.defaultRepo"
#define kRIGConfigs @"com.lzwjava.reveal-in-github.configs"

@interface RIGSetting()

@property (nonatomic, strong) NSString *gitPath;

@end

@implementation RIGSetting

+ (RIGSetting *)setting {
    static dispatch_once_t once;
    static RIGSetting *defaultSetting;
    dispatch_once(&once, ^ {
        defaultSetting = [[RIGSetting alloc] init];
        
        NSDictionary *defaults = @{kRIGConfigs: [[self class] dictsForConfigs:[[self class] defaultConfigs]]};
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    });
    return defaultSetting;
}

+ (RIGSetting *)settingForGitPath:(NSString *)gitPath {
    RIGSetting *setting = [[RIGSetting alloc] init];
    setting.gitPath = gitPath;
    return setting;
}

- (NSArray *)configs {
    NSArray *configDicts = [[NSUserDefaults standardUserDefaults] objectForKey:kRIGConfigs];
    NSMutableArray *configs = [NSMutableArray array];
    for (NSDictionary *configDict in configDicts) {
        RIGConfig *config = [[RIGConfig alloc] initWithDictionary:configDict];
        [configs addObject:config];
    }
    return configs;
}

- (void)setConfigs:(NSArray *)configs {
    NSArray *dicts = [[self class] dictsForConfigs:configs];
    [[NSUserDefaults standardUserDefaults] setObject:dicts forKey:kRIGConfigs];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray *)dictsForConfigs:(NSArray *)configs {
    NSMutableArray *dicts = [NSMutableArray array];
    for (RIGConfig *config in configs) {
        NSDictionary *dict = [config dictionary];
        if (dict.count > 0) {
            [dicts addObject:dict];
        }
    }
    return dicts;
}

+ (NSArray *)defaultConfigs {
    RIGConfig *config1 = [RIGConfig configWithMenuTitle:@"Repo" lastKey:@"R" pattern:@"{git_remote_url}"];
    
    RIGConfig *config2 = [RIGConfig configWithMenuTitle:@"Issues" lastKey:@"I" pattern:@"{git_remote_url}/issues"];
    
    RIGConfig *config3 = [RIGConfig configWithMenuTitle:@"PRs" lastKey:@"P" pattern:@"{git_remote_url}/pulls"];
    
    RIGConfig *config4 = [RIGConfig configWithMenuTitle:@"Quick File" lastKey:@"Q" pattern:@"{git_remote_url}/blob/{commit}/{file_path}#{selection}"];
    
    RIGConfig *config5 = [RIGConfig configWithMenuTitle:@"List History" lastKey:@"L" pattern:@"{git_remote_url}/commits/{commit}/{file_path}"];
    
    RIGConfig *config6 = [RIGConfig configWithMenuTitle:@"Blame" lastKey:@"B" pattern:@"{git_remote_url}/blame/{commit}/{file_path}#{selection}"];
    
    RIGConfig *config7 = [RIGConfig configWithMenuTitle:@"Notifications" lastKey:@"N" pattern:@"{git_remote_url}/notifications?all=1"];
    
    return @[config1, config2, config3, config4, config5, config6, config7];
}

#pragma mark -

- (NSString *)defaultRepoKey {
    return [NSString stringWithFormat:@"%@:%@", kRIGDefaultRepo, self.gitPath];
}

- (void)setDefaultRepo:(NSString *)defaultRepo {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (defaultRepo == nil) {
        [ud removeObjectForKey:[self defaultRepoKey]];
    } else {
        [ud setObject:defaultRepo forKey:[self defaultRepoKey]];
    }
    [ud synchronize];
}

- (NSString *)defaultRepo {
    return [[NSUserDefaults standardUserDefaults] stringForKey:[self defaultRepoKey]];
}

@end
