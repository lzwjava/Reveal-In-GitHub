//
//  RIGConfigCellView.m
//  Reveal-In-Github
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGConfigCellView.h"

#define kHorizontalMargin 8
#define kVerticalMargin 2
#define kTextFieldHeight 25
#define kMenuTitleWidth 100
#define kLastKeyWidth 30

@interface RIGConfigCellView()<NSTextFieldDelegate>

@end

@implementation RIGConfigCellView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        self.wantsLayer = YES;
//        self.layer.backgroundColor = [NSColor greenColor].CGColor;
        [self addSubview:self.menuTitleField];
        [self addSubview:self.lastKeyField];
        [self addSubview:self.patternField];
    }
    return self;
}

+ (CGFloat)heightForCellView {
    return kVerticalMargin * 2 + kTextFieldHeight;
}

- (void)commonInitTextField:(NSTextField *)textField {
    textField.cell.wraps = NO;
    textField.cell.scrollable = YES;
    textField.delegate = self;
//    textField.font = [NSFont systemFontOfSize:16];
}

- (NSTextField *)menuTitleField {
    if (_menuTitleField == nil) {
        _menuTitleField = [[NSTextField alloc] initWithFrame:CGRectMake(kHorizontalMargin, kVerticalMargin, kMenuTitleWidth, kTextFieldHeight)];
        [self commonInitTextField:_menuTitleField];
    }
    return _menuTitleField;
}

- (NSTextField *)lastKeyField {
    if (_lastKeyField == nil) {
        _lastKeyField = [[NSTextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.menuTitleField.frame) + kHorizontalMargin, kVerticalMargin , kLastKeyWidth, kTextFieldHeight)];
        [self commonInitTextField:_lastKeyField];
    }
    return _lastKeyField;
}

- (NSTextField *)patternField {
    if (_patternField == nil) {
        CGFloat maxX = CGRectGetMaxX(self.lastKeyField.frame);
        _patternField = [[NSTextField alloc] initWithFrame:CGRectMake(maxX + kHorizontalMargin, kVerticalMargin , CGRectGetWidth(self.frame) - maxX - 2 * kHorizontalMargin, kTextFieldHeight)];
        [self commonInitTextField:_patternField];
    }
    return _patternField;
}

- (void)reloadData {
    [self.config removeNil];
    self.menuTitleField.stringValue = self.config.menuTitle;
    self.lastKeyField.stringValue = self.config.lastKey;
    self.patternField.stringValue = self.config.pattern;
    if (self.config) {
        NSDictionary* textFieldBindingOptions = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSValidatesImmediatelyBindingOption, [NSNumber numberWithBool:YES], NSContinuouslyUpdatesValueBindingOption,
                                                 nil];
        [self.menuTitleField bind:@"value" toObject:self.config withKeyPath:@"menuTitle" options:textFieldBindingOptions];
        [self.lastKeyField bind:@"value" toObject:self.config withKeyPath:@"lastKey" options:textFieldBindingOptions];
        [self.patternField bind:@"value" toObject:self.config withKeyPath:@"pattern" options:textFieldBindingOptions];
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSLog(@"Did change");
}

@end
