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

#define kOutterXMargin 30
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
    
    self.configs = [[RIGPlugin shared] localConfigs];
    self.configCellsView = [[RIGConfigCellsView alloc] initWithFrame:CGRectMake(kOutterXMargin, kOutterYMargin, CGRectGetWidth(self.window.frame) - 2 * kOutterXMargin, [RIGConfigCellsView heightForConfigs:self.configs])];
    self.configCellsView.configs = self.configs;
    [self.configsView addSubview:self.configCellsView];
    [self.configCellsView reloadData];
}

- (IBAction)saveButtonClcked:(id)sender {
    [[RIGPlugin shared] saveConfigs:self.configCellsView.configs];
}

- (IBAction)clearButtonClicked:(id)sender {
    [[RIGPlugin shared] clearDefaultRepo];
}

@end
