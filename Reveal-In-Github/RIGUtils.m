//
//  RIGUtils.m
//  Reveal-In-Github
//
//  Created by lzw on 15/10/31.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGUtils.h"
#import <Cocoa/Cocoa.h>

@implementation RIGUtils

+ (void)showMessage:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText: message];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}

@end
