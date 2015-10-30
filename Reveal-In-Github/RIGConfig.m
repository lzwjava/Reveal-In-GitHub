//
//  RIGConfig.m
//  Reveal-In-Github
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGConfig.h"

#define SEL_TO_STRING(sel) NSStringFromSelector(@selector(sel))

@implementation RIGConfig

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _menuTitle = dict[SEL_TO_STRING(menuTitle)];
        _lastKey = dict[SEL_TO_STRING(lastKey)];
        _pattern = dict[SEL_TO_STRING(pattern)];
    }
    return self;
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (self.menuTitle) {
        [dict setObject:self.menuTitle forKey:SEL_TO_STRING(menuTitle)];
    }
    if (self.lastKey) {
        [dict setObject:self.lastKey forKey:SEL_TO_STRING(lastKey)];
    }
    if (self.pattern) {
        [dict setObject:self.pattern forKey:SEL_TO_STRING(pattern)];
    }
    return dict;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"RIGConfig <menuTitle:%@, lastKey:%@, pattern:%@", self.menuTitle, self.lastKey, self.pattern];
}

@end
