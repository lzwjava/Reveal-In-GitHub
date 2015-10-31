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

#ifdef DEBUG
#   define LZLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define LZLog(fmt, ...)
#endif

id objc_getClass(const char* name);

#define kRIGDefaultRepo @"com.lzwjava.reveal-in-github.defaultRepo"
#define kRIGConfigs @"com.lzwjava.reveal-in-github.configs"
#define kRIGMenuToInsert @"Window"

static Class DVTSourceTextViewClass;
static Class IDESourceCodeEditorClass;
static Class IDEApplicationClass;
static Class IDEWorkspaceWindowControllerClass;

@interface RIGPlugin()

@property (nonatomic, strong) id ideWorkspaceWindow;
@property (nonatomic, strong) id sourceTextView;
@property (nonatomic, assign) NSUInteger selectionStartLineNumber;
@property (nonatomic, assign) NSUInteger selectionEndLineNumber;
@property (nonatomic, assign) BOOL useHTTPS;

@property (nonatomic, strong) NSWindowController *setttingController;

@end

@implementation RIGPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin {
    DVTSourceTextViewClass = objc_getClass("DVTSourceTextView");
    IDESourceCodeEditorClass = objc_getClass("IDESourceCodeEditor");
    IDEApplicationClass = objc_getClass("IDEApplication");
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
    
    NSArray *configs = [self localConfigs];
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
    [nc addObserver:self selector:@selector(didChangeMenuItem:) name:NSMenuDidChangeItemNotification object:nil];
    [nc addObserver:self selector:@selector(applicationUnderMouseProjectName:) name:@"DVTSourceExpressionUnderMouseDidChangeNotification" object:nil];
    
    [nc addObserver:self selector:@selector(didChangeStateOfIDEIndex:) name:@"IDEIndexDidChangeStateNotification" object:nil];
    
    [nc addObserver:self selector:@selector(sourceTextViewSelectionDidChange:) name:NSTextViewDidChangeSelectionNotification object:nil];
    
    [nc addObserver:self selector:@selector(fetchActiveIDEWorkspaceWindow:) name:NSWindowDidUpdateNotification object:nil];
}

- (void)didChangeMenuItem:(NSNotification *)noti {
//    if ([[noti.object title] isEqualToString:kRIGMenuToInsert]) {
//        @synchronized(self) {
//            [self addMenu];
//        }
//    }
}

- (void)applicationUnderMouseProjectName:(NSNotification *)noti {
    
}

- (void)didChangeStateOfIDEIndex:(NSNotification *)noti {
    
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

- (void)showMessage:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText: message];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
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
    self.selectionEndLineNumber = self.selectionStartLineNumber + (selectedLines > 1 ? selectedLines - 2 : 0);
}

- (NSString *)selectedLineString {
    NSRange selectedRange = [self.sourceTextView selectedRange];
    NSString *sourceTextUntilSelection = [[self.sourceTextView string] substringWithRange:NSMakeRange(0, selectedRange.location)];
    
    NSArray *components = [sourceTextUntilSelection componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSInteger selectedLineNumber = components.count;
    
    NSString *lineString = [[[self.sourceTextView string] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:selectedLineNumber - 1];
    return lineString;
}

#pragma mark - Remote Repo

- (NSString *)defaultRepoKey {
    NSString *gitPath = [self gitRootPath];
    return [NSString stringWithFormat:@"%@:%@", kRIGDefaultRepo, gitPath];
}

- (void)setDefaultRepo:(NSString *)defaultRepo {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:defaultRepo forKey:[self defaultRepoKey]];
}

- (void)removeDefaultRepo {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:[self defaultRepoKey]];
}

- (NSString *)defaultRepo {
    return [[NSUserDefaults standardUserDefaults] stringForKey:[self defaultRepoKey]];
}

- (NSString *)remoteRepoUrl {
    NSString *defaultRepo = [self defaultRepo];
    if (defaultRepo != nil) {
        return defaultRepo;
    } else {
        NSString *selectedRepo = [self getOrAskRemoteRepoUrl];
        [self setDefaultRepo:selectedRepo];
        return selectedRepo;
    }
}

- (NSString *)getOrAskRemoteRepoUrl {
    NSString *rootPath = [self gitRootPath];
    // Get Github username and repo name
    NSArray *args = @[@"remote", @"--verbose"];
    NSString *output = [self outputGitWithArguments:args inPath:rootPath];
    NSArray *remoteURLs = [output componentsSeparatedByString:@"\n"];
    
    NSMutableSet *remotePaths = [NSMutableSet set];
    
    for (NSString *remoteURL in remoteURLs)
    {
        NSString *remotePath = [self remotePathFromRemoteURL:remoteURL];
        if (remotePath) {
            [remotePaths addObject:remotePath];
        }
    }
    
    NSString *selectedRemotePath;
    if (remotePaths.count == 1) {
        selectedRemotePath = [remotePaths allObjects][0];
    } else if (remotePaths.count > 1) {
        NSArray *sortedRemotePaths = remotePaths.allObjects;
        
        // Ask the user what remote to use.
        // Attention: Due to NSRunAlert maximal three remotes are supported.
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSInformationalAlertStyle;
        alert.messageText = [NSString stringWithFormat:@"This repository has %ld remotes configured. Which one do you want to open?", remotePaths.count];
        [alert addButtonWithTitle:[sortedRemotePaths objectAtIndex:0]];
        [alert addButtonWithTitle:[sortedRemotePaths objectAtIndex:1]];
        [alert addButtonWithTitle:(sortedRemotePaths.count > 2 ? [sortedRemotePaths objectAtIndex:2] : nil)];
        
        NSModalResponse button = [alert runModal];
        if (button == NSAlertFirstButtonReturn) {
            selectedRemotePath = sortedRemotePaths[0];
        } else if (button == NSAlertSecondButtonReturn) {
            selectedRemotePath = sortedRemotePaths[1];
        } else if (button == NSAlertThirdButtonReturn) {
            selectedRemotePath = sortedRemotePaths[2];
        }
    }
    
    if (selectedRemotePath.length == 0)
    {
        LZLog(@"Unable to find github remote URL.");
        return nil;
    }
    
    NSString *fullUrl = [NSString stringWithFormat:@"https://%@", selectedRemotePath];
    
    return fullUrl;
}


#pragma mark - Git Utils

- (NSString *)filenameWithPathInCommit:(NSString *)commitHash {
    NSURL *activeDocumentURL = [self activeDocument];
    return [self filenameWithPathInCommit:commitHash forActiveDocumentURL:activeDocumentURL];
}

- (NSString *)filenameWithPathInCommit:(NSString *)commitHash forActiveDocumentURL:(NSURL *)activeDocumentURL {
    NSArray *args = @[@"show", @"--name-only", @"--pretty=format:", commitHash];
    NSString *activeDocumentDirectoryPath = [[activeDocumentURL URLByDeletingLastPathComponent] path];
    NSString *files = [self outputGitWithArguments:args inPath:activeDocumentDirectoryPath];
    
    NSString *activeDocumentFilename = [activeDocumentURL lastPathComponent];
    NSString *filenameWithPathInCommit = nil;
    for (NSString *filenameWithPath in [files componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]])
    {
        if ([filenameWithPath hasSuffix:activeDocumentFilename])
        {
            filenameWithPathInCommit = [filenameWithPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            break;
        }
    }
    
    if (!filenameWithPathInCommit)
    {
        LZLog(@"Unable to find file in commit.");
        return nil;
    }
    
    return filenameWithPathInCommit;
}

- (NSString *)latestCommitHash {
    NSURL *activeDocumentURL = [self activeDocument];
    NSString *activeDocumentFullPath = [activeDocumentURL path];
    NSString *activeDocumentDirectoryPath = [[activeDocumentURL URLByDeletingLastPathComponent] path];
    // Get last commit hash
    NSArray *args = @[@"log", @"-n1", @"--no-decorate", activeDocumentFullPath];
    NSString *rawLastCommitHash = [self outputGitWithArguments:args inPath:activeDocumentDirectoryPath];
    LZLog(@"GIT log: %@", rawLastCommitHash);
    NSArray *commitHashInfo = [rawLastCommitHash componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (commitHashInfo.count < 2)
    {
        [self showMessage:@"Unable to find lastest commit."];
        return nil;
    }
    
    NSString *commitHash = [commitHashInfo objectAtIndex:1];
    return commitHash;
}

- (NSString *)gitRootPath {
    NSURL *activeDocumentURL = [self activeDocument];
    NSString *activeDocumentDirectoryPath = [[activeDocumentURL URLByDeletingLastPathComponent] path];
    NSArray *args = @[@"rev-parse", @"--show-toplevel"];
    NSString *rootPath = [self outputGitWithArguments:args inPath:activeDocumentDirectoryPath];
    return [rootPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// Performs a git command with given args in the given directory
- (NSString *)outputGitWithArguments:(NSArray *)args inPath:(NSString *)path
{
    if (path.length == 0)
    {
        LZLog(@"Invalid path for git working directory.");
        return nil;
    }
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/xcrun";
    task.currentDirectoryPath = path;
    task.arguments = [@[@"git", @"--no-pager"] arrayByAddingObjectsFromArray:args];
    task.standardOutput = [NSPipe pipe];
    NSFileHandle *file = [task.standardOutput fileHandleForReading];
    
    [task launch];
    
    // For some reason [task waitUntilExit]; does not return sometimes. Therefore this rather hackish solution:
    int count = 0;
    while (task.isRunning && (count < 10))
    {
        [NSThread sleepForTimeInterval:0.1];
        count++;
    }
    
    NSString *output = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    
    return output;
}

- (NSString *)remotePathFromRemoteURL:(NSString *)remotePath {
    // Check for SSH protocol
    NSRange begin = [remotePath rangeOfString:@"git@"];
    
    if (begin.location == NSNotFound)
    {
        // SSH protocol not found, check for GIT protocol
        begin = [remotePath rangeOfString:@"git://"];
    }
    if (begin.location == NSNotFound)
    {
        // HTTPS protocol check
        begin = [remotePath rangeOfString:@"https://"];
    }
    if (begin.location == NSNotFound)
    {
        // HTTP protocol check
        begin = [remotePath rangeOfString:@"http://"];
    }
    
    NSRange end = [remotePath rangeOfString:@".git (fetch)"];
    
    if (end.location == NSNotFound)
    {
        // Alternate remote url end
        end = [remotePath rangeOfString:@" (fetch)"];
    }
    
    if ((begin.location != NSNotFound) &&
        (end.location != NSNotFound))
    {
        NSUInteger githubURLBegin = begin.location + begin.length;
        NSUInteger githubURLLength = end.location - githubURLBegin;
        return [[remotePath
                 substringWithRange:NSMakeRange(githubURLBegin, githubURLLength)]
                stringByReplacingOccurrencesOfString:@":" withString:@"/"];
    } else {
        return nil;
    }
}

- (void)openUrl:(NSString *)url {
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[url]];
}

- (void)openRepo:(NSString *)repo withPath:(NSString *)path {
    NSString *secureBaseUrl = [NSString stringWithFormat:@"https://%@", repo];
    NSString *url = [NSString stringWithFormat:@"%@%@", secureBaseUrl, path];
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[url]];
}

#pragma mark - Clear Default Repo 

- (void)clearDefaultRepo {
    NSString *defaultRepo = [self defaultRepo];
    if (defaultRepo == nil) {
        [self showMessage:@"There's no default repo setting."];
    } else {
        [self removeDefaultRepo];
        [self showMessage:[NSString stringWithFormat:@"Succeed to clear current default repo(%@) setting. In the next time to open github, will ask you to select new default repo.", defaultRepo]];
    }
}

#pragma mark - Check 

- (BOOL)isValidGitRepo {
    NSURL *activeDocument = [self activeDocument];
    if (activeDocument == nil) {
        [self showMessage:@"No file is opening now."];
        return NO;
    }
    NSString *gitPath = [self gitRootPath];
    if (!gitPath) {
        [self showMessage:@"Could not get git repo from current file."];
        return NO;
    }
    return YES;
}

#pragma mark - Show Settings

- (void)showSettingWindow:(id)sender {
    self.setttingController = [[RIGSettingWindowController alloc] initWithWindowNibName:@"RIGSettingWindowController"];
    [self.setttingController showWindow:self.setttingController];
}

- (NSArray *)defaultConfigs {
    RIGConfig *config1 = [RIGConfig configWithMenuTitle:@"Repo" lastKey:@"R" pattern:@"{git_remote_url}"];
    
    RIGConfig *config2 = [RIGConfig configWithMenuTitle:@"Issues" lastKey:@"I" pattern:@"{git_remote_url}/issues"];
    
    RIGConfig *config3 = [RIGConfig configWithMenuTitle:@"PRs" lastKey:@"P" pattern:@"{git_remote_url}/pulls"];
    
    RIGConfig *config4 = [RIGConfig configWithMenuTitle:@"Quick File" lastKey:@"Q" pattern:@"{git_remote_url}/blob/{commit}/{file_path}#{selection}"];
    
    RIGConfig *config5 = [RIGConfig configWithMenuTitle:@"List History" lastKey:@"L" pattern:@"{git_remote_url}/commits/{commit}/{file_path}"];
    
    RIGConfig *config6 = [RIGConfig configWithMenuTitle:@"Blame" lastKey:@"B" pattern:@"{git_remote_url}/blame/{commit}/{file_path}#{selection}"];
    
    RIGConfig *config7 = [RIGConfig configWithMenuTitle:@"Notifications" lastKey:@"N" pattern:@"{git_remote_url}/notifications?all=1"];
    
    return @[config7, config6, config5, config4, config3, config2, config1];
}

- (NSArray *)localConfigs {
    NSArray *configDicts = [[NSUserDefaults standardUserDefaults] objectForKey:kRIGConfigs];
    if (configDicts == nil) {
        [self saveConfigs:[self defaultConfigs]];
        return [self localConfigs];
    }
    NSMutableArray *configs = [NSMutableArray array];
    for (NSDictionary *configDict in configDicts) {
        RIGConfig *config = [[RIGConfig alloc] initWithDictionary:configDict];
        [configs addObject:config];
    }
    return configs;
}

- (BOOL)isValidConfig:(RIGConfig *)config {
    return config.menuTitle.length != 0 && config.lastKey.length != 0 && config.pattern.length != 0;
}

- (void)clearConfigs {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRIGConfigs];
}

- (void)saveConfigs:(NSArray *)configs {
    NSMutableArray *dicts = [NSMutableArray array];
    for (RIGConfig *config in configs) {
        NSDictionary *dict = [config dictionary];
        if (dict.count > 0) {
            BOOL isValid = [self isValidConfig:config];
            if (!isValid) {
                [self showMessage:@"Please complete the config, should have all three values."];
                return;
            }
            [dicts addObject:dict];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:dicts forKey:kRIGConfigs];
}

#pragma mark - Custom

- (NSDictionary *)currentRepoInfos {
    NSMutableDictionary *dict= [[NSMutableDictionary alloc] init];
    NSString *gitRemoteUrl = [self remoteRepoUrl];
    if (gitRemoteUrl) {
        [dict setObject:gitRemoteUrl forKey:@"{git_remote_url}"];
    }
    NSString *commit = [self latestCommitHash];
    if (commit) {
        [dict setObject:commit forKey:@"{commit}"];
        NSString *filePath = [self filenameWithPathInCommit:commit];
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

- (void)customMenusClicked:(NSMenuItem *)menuItem {
    if (![self isValidGitRepo]) {
        return;
    }
    
    RIGConfig *currentConfig = nil;
    for (RIGConfig *confing in [self localConfigs]) {
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

@end
