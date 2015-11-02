//
//  RIGConfigCellView.h
//  Reveal-In-GitHub
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RIGConfig.h"

@interface RIGConfigCellView : NSView

@property (nonatomic, strong) NSTextField *menuTitleField;
@property (nonatomic, strong) NSTextField *lastKeyField;
@property (nonatomic, strong) NSTextField *patternField;

@property (nonatomic, strong) RIGConfig *config;

+ (CGFloat)heightForCellView;

- (void)reloadData;

@end
