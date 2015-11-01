//
//  GithubKitPlugin.m
//  GithubKitPlugin
//
//  Created by lzw on 15/10/22.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RIGPlugin.h"
#import "RIGSettingWindowController.h"
#import "RIGConfig.h"
#import "RIGUtils.h"
#import "RIGGitRepo.h"
#import "RIGSetting.h"

id objc_getClass(const char* name);

#define kRIGMenuToInsert @"Window"

static Class DVTSourceTextViewClass;
static Class IDEWorkspaceWindowControllerClass;

@interface RIGPlugin()

@property (nonatomic, strong) id ideWorkspaceWindow;
@property (nonatomic, strong) id sourceTextView;
@property (nonatomic, assign) NSUInteger selectionStartLineNumber;
@property (nonatomic, assign) NSUInteger selectionEndLineNumber;
@property (nonatomic, assign) BOOL useHTTPS;

@property (nonatomic, strong) RIGSettingWindowController *setttingController;

@property (nonatomic, strong) RIGGitRepo *gitRepo;

@end

@implementation RIGPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin {
    DVTSourceTextViewClass = objc_getClass("DVTSourceTextView");
    IDEWorkspaceWindowControllerClass = objc_getClass("IDEWorkspaceWindowController");
    [self shared];
}

#pragma mark - init

- (instancetype)init {
    if (self = [super init]) {
        [self addNotification];
    }
    return self;
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Menu init

- (BOOL)menuExists {
    NSMenuItem *windowMenuItem = [[NSApp mainMenu] itemWithTitle:kRIGMenuToInsert];
    NSMenuItem *menu = [windowMenuItem.submenu itemWithTitle:@"Reveal In Github"];
    return menu != nil;
}

- (NSMenu *)githubMenu
{
    NSMenuItem *windowMenuItem = [[NSApp mainMenu] itemWithTitle:kRIGMenuToInsert];
    
    [[windowMenuItem submenu] addItem:[NSMenuItem separatorItem]];
    NSMenuItem *githubMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Reveal In Github" action:NULL keyEquivalent:@""];
    githubMenuItem.enabled = YES;
    githubMenuItem.submenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Reveal In Github"];
    [windowMenuItem.submenu addItem:githubMenuItem];
    
    return githubMenuItem.submenu;
}

- (void)applicationDidFinishLaunching:(NSNotification *)noti {
    [self addMenu];
}

- (void)addMenu {
    if ([self menuExists]) {
        return;
    }
    
    NSMenu *githubMenu = [self githubMenu];
    
    NSMenuItem *settings = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Settings" action:@selector(showSettingWindow:) keyEquivalent:@"S"];
    [settings setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];
    settings.target = self;
    [githubMenu addItem:settings];
    
    NSArray *configs = [RIGSetting setting].configs;
    for (RIGConfig *config in configs) {
        NSString *keyEquivalent = config.lastKey;
        if (keyEquivalent == nil) {
            keyEquivalent = @"";
        }
        NSMenuItem *configItem = [[NSMenuItem alloc] initWithTitle:config.menuTitle action:@selector(customMenusClicked:) keyEquivalent:keyEquivalent];
        if (keyEquivalent.length > 0) {
            [configItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];
        }
        configItem.target = self;
        [githubMenu addItem:configItem];
    }
}

#pragma mark - Notification and Selectors

- (void)addNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    [nc addObserver:self selector:@selector(sourceTextViewSelectionDidChange:) name:NSTextViewDidChangeSelectionNotification object:nil];
    
    [nc addObserver:self selector:@selector(fetchActiveIDEWorkspaceWindow:) name:NSWindowDidUpdateNotification object:nil];
}

- (void)sourceTextViewSelectionDidChange:(NSNotification *)notification {
    id view = [notification object];
    if ([view isMemberOfClass:DVTSourceTextViewClass])
    {
        self.sourceTextView = view;
    }
}

- (void)fetchActiveIDEWorkspaceWindow:(NSNotification *)notification {
    id window = [notification object];
    if ([window isKindOfClass:[NSWindow class]] && [window isMainWindow])
    {
        self.ideWorkspaceWindow = window;
    }
}

#pragma mark - Xcode Part

- (NSURL *)activeDocument
{
    NSArray *windows = [IDEWorkspaceWindowControllerClass valueForKey:@"workspaceWindowControllers"];
    for (id workspaceWindowController in windows)
    {
        if ([workspaceWindowController valueForKey:@"workspaceWindow"] == self.ideWorkspaceWindow || windows.count == 1)
        {
            id document = [[workspaceWindowController valueForKey:@"editorArea"] valueForKey:@"primaryEditorDocument"];
            return [document fileURL];
        }
    }
    
    return nil;
}

- (void)findSelection {
    if (self.sourceTextView == nil) {
        return;
    }
    NSRange selectedRange = [self.sourceTextView selectedRange];
    NSString *sourceTextUntilSelection = [[self.sourceTextView string] substringWithRange:NSMakeRange(0, selectedRange.location)];
    
    self.selectionStartLineNumber = [[sourceTextUntilSelection componentsSeparatedByCharactersInSet:
                                      [NSCharacterSet newlineCharacterSet]] count];
    
    NSString *sourceTextSelection = [[self.sourceTextView string] substringWithRange:selectedRange];
    NSUInteger selectedLines = [[sourceTextSelection componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
    self.selectionEndLineNumber = self.selectionStartLineNumber + (selectedLines > 1 ? selectedLines - 1 : 0);
}

- (NSString *)selectedLineString {
    NSRange selectedRange = [self.sourceTextView selectedRange];
    NSString *sourceTextUntilSelection = [[self.sourceTextView string] substringWithRange:NSMakeRange(0, selectedRange.location)];
    
    NSArray *components = [sourceTextUntilSelection componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSInteger selectedLineNumber = components.count;
    
    NSString *lineString = [[[self.sourceTextView string] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:selectedLineNumber - 1];
    return lineString;
}

- (void)openUrl:(NSString *)url {
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[url]];
}

#pragma mark - Show Settings

- (void)showSettingWindow:(id)sender {
    if (![self trySetGitRepo]) {
        return;
    }
    self.setttingController = [[RIGSettingWindowController alloc] initWithWindowNibName:@"RIGSettingWindowController"];
    self.setttingController.gitRepo = self.gitRepo;
    [self.setttingController showWindow:self.setttingController];
}

#pragma mark - Git Menu Actions

- (NSDictionary *)currentRepoInfos {
    NSMutableDictionary *dict= [[NSMutableDictionary alloc] init];
    NSString *gitRemoteUrl = [self.gitRepo remoteRepoUrl];
    if (gitRemoteUrl) {
        [dict setObject:gitRemoteUrl forKey:@"{git_remote_url}"];
    }
    NSString *commit = [self.gitRepo latestCommitHash];
    if (commit) {
        [dict setObject:commit forKey:@"{commit}"];
        NSString *filePath = [self.gitRepo filenameWithPathInCommit:commit];
        if (filePath) {
            [dict setObject:filePath forKey:@"{file_path}"];
        }
    }
    NSString *selection = [self selectionString];
    if (selection) {
        [dict setObject:selection forKey:@"{selection}"];
    }
    return dict;
}

- (NSString *)selectionString {
    [self findSelection];
    
    NSUInteger start = self.selectionStartLineNumber;
    NSUInteger end = self.selectionEndLineNumber;
    
    if (start == end) {
        return [NSString stringWithFormat:@"L%ld", start];
    } else {
        return [NSString stringWithFormat:@"L%ld-L%ld", start, end];
    }
}

- (BOOL)trySetGitRepo {
    NSURL *activeDocumentURL = [self activeDocument];
    if (activeDocumentURL == nil) {
        [self showMessage:@"No file is opening now."];
        return NO;
    }
    self.gitRepo = [[RIGGitRepo alloc] initWithDocumentURL:[self activeDocument]];
    if (![self.gitRepo isValid]) {
        [self showMessage:@"Could not get git repo from current file."];
        return NO;
    }
    return YES;
}

- (void)customMenusClicked:(NSMenuItem *)menuItem {
    if (![self trySetGitRepo]) {
        return;
    }
    
    RIGConfig *currentConfig = nil;
    for (RIGConfig *confing in [RIGSetting setting].configs) {
        if ([confing.menuTitle isEqualToString:menuItem.title]) {
            currentConfig = confing;
            break;
        }
    }
    
    NSDictionary *infos = [self currentRepoInfos];
    NSMutableString *url = [[NSMutableString alloc] initWithString:currentConfig.pattern];
    for (NSString *key in [infos allKeys]) {
        NSString *value = [infos objectForKey:key];
        [url replaceOccurrencesOfString:key withString:value options:NSLiteralSearch range:NSMakeRange(0, url.length)];
    }
    [self openUrl:url];
}

- (void)showMessage:(NSString *)message {
    [RIGUtils showMessage:message];
}

@end
