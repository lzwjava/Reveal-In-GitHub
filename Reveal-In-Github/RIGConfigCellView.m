//
//  RIGConfigCellView.m
//  Reveal-In-Github
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGConfigCellView.h"

@interface RIGConfigCellView()

@property (weak) IBOutlet NSTextField *menuTitleField;
@property (weak) IBOutlet NSTextField *lastKeyField;
@property (weak) IBOutlet NSTextField *patternField;

@end

@implementation RIGConfigCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

- (void)reloadData {
    self.menuTitleField.stringValue = self.config.menuTitle;
    self.lastKeyField.stringValue = self.config.lastKey;
    self.patternField.stringValue = self.config.pattern;
}

@end
