//
//  RIGConfigCellViews.h
//  Reveal-In-Github
//
//  Created by lzw on 15/10/30.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RIGConfigCellsView : NSView

@property (nonatomic, strong) NSArray *configs;

+ (CGFloat)heightForConfigs:(NSArray *)configs;

- (void)reloadData;

@end
