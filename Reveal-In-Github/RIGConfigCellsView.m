//
//  RIGConfigCellViews.m
//  Reveal-In-Github
//
//  Created by lzw on 15/10/30.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGConfigCellsView.h"
#import "RIGConfigCellView.h"

#define kVerticalMargin 5

@interface RIGConfigCellsView()

@property (nonatomic, strong) NSMutableArray *cellViews;

@end

@implementation RIGConfigCellsView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _cellViews = [NSMutableArray array];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

+ (CGFloat)heightForConfigs:(NSArray *)configs {
    return configs.count * [RIGConfigCellView heightForCellView] + (configs.count - 1) * kVerticalMargin;
}

- (void)reloadData {
    CGFloat w = CGRectGetWidth(self.frame);
    for (NSView *view in self.cellViews) {
        [view removeFromSuperview];
    }
    for (RIGConfig *config in self.configs) {
        NSInteger index = [self.configs indexOfObject:config];
        CGFloat subH = [RIGConfigCellView heightForCellView];
        CGFloat y = (self.configs.count - 1 - index) * (subH + kVerticalMargin);
        RIGConfigCellView *cellView = [[RIGConfigCellView alloc] initWithFrame:NSRectFromCGRect(CGRectMake(0, y, w, subH))];
        cellView.config = config;
        [cellView reloadData];
        [self.cellViews addObject:cellView];
        [self addSubview:cellView];
    }
}

@end
