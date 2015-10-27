//
//  RIGConfigCellView.h
//  Reveal-In-Github
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RIGConfigCellView : NSTableCellView

@property (weak) IBOutlet NSTextField *menuTitleField;
@property (weak) IBOutlet NSTextField *lastKeyField;
@property (weak) IBOutlet NSTextField *patternField;

@end
