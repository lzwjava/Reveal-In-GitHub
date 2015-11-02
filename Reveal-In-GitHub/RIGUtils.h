//
//  RIGUtils.h
//  Reveal-In-GitHub
//
//  Created by lzw on 15/10/31.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#ifdef DEBUG
#   define LZLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define LZLog(fmt, ...)
#endif

@interface RIGUtils : NSObject

+ (NSModalResponse)showMessage:(NSString *)message;

@end
