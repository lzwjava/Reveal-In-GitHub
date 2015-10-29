//
//  RIGSettingWindowController.m
//  Reveal-In-Github
//
//  Created by lzw on 15/10/28.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGSettingWindowController.h"
#import "RIGConfigCellView.h"

@interface RIGSettingWindowController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) NSArray *configs;

@end

@implementation RIGSettingWindowController

- (void)awakeFromNib {
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
//    
//    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"RIGConfigCellView" bundle:[NSBundle mainBundle]];
//    [self.tableView registerNib:nib forIdentifier:@"MainCell"];
//    
    NSNib *testNib = [[NSNib alloc] initWithNibNamed:@"RIGTestView" bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:testNib forIdentifier:@"tesNib"];
    
//    RIGConfig *config= [[RIGConfig alloc] init];
//    config.menuTitle = @"Notification";
//    config.lastKey = @"N";
//    config.pattern = @"{{git_remote_url}}/notifications?all=1";
//    self.configs = @[config];
//    [self.tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.configs.count;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    RIGConfigCellView *configCell = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    configCell.config = self.configs[row];
    [configCell reloadData];
    return configCell;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView {
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return NO;
}

@end
