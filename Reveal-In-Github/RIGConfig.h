//
//  RIGConfig.h
//  Reveal-In-Github
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RIGConfig : NSObject

@property (nonatomic, strong) NSString *menuTitle;
@property (nonatomic, strong) NSString *lastKey;
@property (nonatomic, strong) NSString *pattern;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionary;

+ (instancetype)configWithMenuTitle:(NSString *)menuTitle lastKey:(NSString *)lastKey pattern:(NSString *)pattern;

- (BOOL)isValid;

- (void)removeNil;

@end
