//
//  RIGConfigCellView.h
//  Reveal-In-Github
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RIGConfig.h"

@interface RIGConfigCellView : NSView

@property (nonatomic, strong) RIGConfig *config;

- (void)reloadData;

@end
