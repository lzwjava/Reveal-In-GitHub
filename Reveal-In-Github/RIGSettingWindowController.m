//
//  RIGSettingWindowController.m
//  Reveal-In-Github
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGSettingWindowController.h"
#import "RIGConfigCellsView.h"
#import "RIGConfig.h"
#import "RIGPlugin.h"

#define kOutterXMargin 0
#define kOutterYMargin 0

@interface RIGSettingWindowController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) NSArray *configs;
@property (nonatomic, strong) RIGConfigCellsView *configCellsView;
@property (weak) IBOutlet NSView *mainView;
@property (weak) IBOutlet NSView *configsView;

@end

@implementation RIGSettingWindowController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    self.configs = [self displayConfigs];
    
    self.configCellsView = [[RIGConfigCellsView alloc] initWithFrame:CGRectMake(kOutterXMargin, kOutterYMargin, CGRectGetWidth(self.configsView.frame) - 2 * kOutterXMargin, [RIGConfigCellsView heightForConfigs:self.configs])];
    self.configCellsView.configs = self.configs;
    [self.configsView addSubview:self.configCellsView];
//    [self updateConfigsViewHeight];
    [self.configCellsView reloadData];
}

- (void)updateConfigsViewHeight {
    CGRect frame = self.configsView.frame;
    frame.size.height = CGRectGetHeight(self.configCellsView.frame);
    self.configsView.frame = frame;
}

- (NSMutableArray *)displayConfigs {
    NSMutableArray *configs = [NSMutableArray arrayWithArray:[[RIGPlugin shared] localConfigs]];
    while (configs.count < 10) {
        RIGConfig *config = [[RIGConfig alloc] init];
        config.menuTitle = @"";
        config.lastKey = @"";
        config.pattern = @"";
        [configs insertObject:config atIndex:0];
    }
    return configs;
}

- (void)reloadConfigs {
    self.configs = [self displayConfigs];
    self.configCellsView.configs = self.configs;
    [self.configCellsView reloadData];
}

- (IBAction)saveButtonClcked:(id)sender {
    [[RIGPlugin shared] saveConfigs:self.configCellsView.configs];
}

- (IBAction)clearButtonClicked:(id)sender {
    [[RIGPlugin shared] clearDefaultRepo];
}

- (IBAction)resetMenusButtonClicked:(id)sender {
    [[RIGPlugin shared] clearConfigs];
    [self reloadConfigs];
}

@end
