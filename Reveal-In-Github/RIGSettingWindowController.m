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

@end

@implementation RIGSettingWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 1;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    RIGConfigCellView *configCell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    return configCell;
}

@end
