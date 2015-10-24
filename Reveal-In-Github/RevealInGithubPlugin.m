//
//  GithubKitPlugin.m
//  GithubKitPlugin
//
//  Created by lzw on 15/10/22.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RevealInGithubPlugin.h"

#ifdef DEBUG
#   define LZLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define LZLog(fmt, ...)
#endif

id objc_getClass(const char* name);

NSString *const kRIGDefaultRepo = @"com.lzwjava.reveal-in-github.defaultRepo";

static Class DVTSourceTextViewClass;
static Class IDESourceCodeEditorClass;
static Class IDEApplicationClass;
static Class IDEWorkspaceWindowControllerClass;

@interface RevealInGithubPlugin()

@property (nonatomic, strong) id ideWorkspaceWindow;
@property (nonatomic, assign) NSUInteger selectionStartLineNumber;
@property (nonatomic, assign) NSUInteger selectionEndLineNumber;
@property (nonatomic, assign) BOOL useHTTPS;

@end

@implementation RevealInGithubPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin {
    DVTSourceTextViewClass = objc_getClass("DVTSourceTextView");
    IDESourceCodeEditorClass = objc_getClass("IDESourceCodeEditor");
    IDEApplicationClass = objc_getClass("IDEApplication");
    IDEWorkspaceWindowControllerClass = objc_getClass("IDEWorkspaceWindowController");
    [self shared];
}

#pragma mark - init
- (instancetype)init{
    if (self = [super init]) {
        [self addNotification];
    }
    return self;
}

+ (instancetype)shared{
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

#pragma mark - Notification

- (void)addNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
    [nc addObserver:self selector:@selector(applicationDidAddCurrentMenu:) name:NSMenuDidChangeItemNotification object:nil];
    [nc addObserver:self selector:@selector(applicationUnderMouseProjectName:) name:@"DVTSourceExpressionUnderMouseDidChangeNotification" object:nil];
    
    [nc addObserver:self selector:@selector(applicationDidAddNowCurrentProjectName:) name:@"IDEIndexDidChangeStateNotification" object:nil];
    
    [nc addObserver:self selector:@selector(sourceTextViewSelectionDidChange:) name:NSTextViewDidChangeSelectionNotification object:nil];
    
    [nc addObserver:self selector:@selector(fetchActiveIDEWorkspaceWindow:) name:NSWindowDidUpdateNotification object:nil];
}

- (NSMenu *)githubMenu
{
    NSMenuItem *windowMenuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];;
    
    [[windowMenuItem submenu] addItem:[NSMenuItem separatorItem]];
    NSMenuItem *githubMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Reveal In Github" action:NULL keyEquivalent:@""];
    githubMenuItem.enabled = YES;
    githubMenuItem.submenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Reveal In Github"];
    [windowMenuItem.submenu addItem:githubMenuItem];
    
    return githubMenuItem.submenu;
}

- (void)applicationDidFinishLaunching:(NSNotification *)noti {
    // Application did finish launching is only send once. We do not need it anymore.
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
                  name:NSApplicationDidFinishLaunchingNotification
                object:NSApp];
    
    NSMenu *githubMenu = [self githubMenu];
    
    NSMenuItem *history = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"History" action:@selector(openHistory:) keyEquivalent:@"H"];
    [history setKeyEquivalentModifierMask:NSCommandKeyMask];
    history.target = self;
    [githubMenu addItem:history];
    
    NSMenuItem *blame = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Blame" action:@selector(openBlame:) keyEquivalent:@"B"];
    [blame setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask
     ];
    blame.target = self;
    [githubMenu addItem:blame];
    
    NSMenuItem *issue = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Issues" action:@selector(openIssues:) keyEquivalent:@"I"];
    [issue setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask
     ];
    issue.target = self;
    [githubMenu addItem:issue];
    
    NSMenuItem *PR = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"PRs" action:@selector(openPRs:) keyEquivalent:@"P"];
    [PR setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask
     ];
    PR.target = self;
    [githubMenu addItem:PR];
    
    NSMenuItem *clearDefault = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Clear Defaults" action:@selector(clearDefaultRepo:) keyEquivalent:@""];
    clearDefault.target = self;
    [githubMenu addItem:clearDefault];
}

- (void)applicationDidAddCurrentMenu:(NSNotification *)noti {
    LZLog();
}

- (void)applicationUnderMouseProjectName:(NSNotification *)noti {
    LZLog();
}

- (void)applicationDidAddNowCurrentProjectName:(NSNotification *)noti {
    LZLog();
}

- (void)sourceTextViewSelectionDidChange:(NSNotification *)notification {
    id view = [notification object];
    if ([view isMemberOfClass:DVTSourceTextViewClass])
    {
        NSString *sourceTextUntilSelection = [[view string] substringWithRange:NSMakeRange(0, [view selectedRange].location)];
        self.selectionStartLineNumber = [[sourceTextUntilSelection componentsSeparatedByCharactersInSet:
                                          [NSCharacterSet newlineCharacterSet]] count];
        
        NSString *sourceTextSelection = [[view string] substringWithRange:[view selectedRange]];
        NSUInteger selectedLines = [[sourceTextSelection componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
        self.selectionEndLineNumber = self.selectionStartLineNumber + (selectedLines > 1 ? selectedLines - 2 : 0);
    }
}

- (void)fetchActiveIDEWorkspaceWindow:(NSNotification *)notification {
    id window = [notification object];
    if ([window isKindOfClass:[NSWindow class]] && [window isMainWindow])
    {
        self.ideWorkspaceWindow = window;
    }
}

+ (id)workspaceForWindow:(NSWindow *)window
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    
    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] isEqual:window]) {
            return [controller valueForKey:@"_workspace"];
        }
    }
    return nil;
}

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

#pragma mark - Actions

- (void)openBlame:(id)sender {
    NSUInteger startLineNumber = self.selectionStartLineNumber;
    NSUInteger endLineNumber = self.selectionEndLineNumber;
    
    NSURL *activeDocumentURL = [self activeDocument];
    NSString *activeDocumentFullPath = [activeDocumentURL path];
    NSString *activeDocumentDirectoryPath = [[activeDocumentURL URLByDeletingLastPathComponent] path];
    
    NSString *remoteRepoPath = [self remoteRepoPath];
    if (!remoteRepoPath) {
        return;
    }
    
    NSString *commitHash = [self lastestCommitHash];
    if (!commitHash) {
        return;
    }
    
    NSString *filenameWithPathInCommit = [self filenameWithPathInCommit:commitHash forActiveDocumentURL:activeDocumentURL];
    if (!filenameWithPathInCommit) {
        return;
    }
    
    NSMutableString *path = [[NSString stringWithFormat:@"/blame/%@/%@#L%ld",
                           commitHash, filenameWithPathInCommit, startLineNumber] mutableCopy];
    if (startLineNumber != endLineNumber) {
        [path appendFormat:@"-L%ld", endLineNumber];
    }
    [self openRepo:remoteRepoPath withPath:path];
}

// Performs a git command with given args in the given directory
- (NSString *)outputGitWithArguments:(NSArray *)args inPath:(NSString *)path
{
    if (path.length == 0)
    {
        NSLog(@"Invalid path for git working directory.");
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

- (NSString *)remoteRepoPath {
    NSString *defaultRepo = [self defaultRepo];
    if (defaultRepo != nil) {
        return defaultRepo;
    } else {
        NSString *selectedRepo = [self getOrAskRemoteRepoPath];
        [self setDefaultRepo:selectedRepo];
        return selectedRepo;
    }
}

- (NSString *)getOrAskRemoteRepoPath {
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
    
    if (remotePaths.count > 1) {
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
        [self showMessage:@"Unable to find github remote URL."];
        return nil;
    }
    
    return selectedRemotePath;
    
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
        [self showMessage:@"Unable to find file in commit."];
        return nil;
    }
    
    return filenameWithPathInCommit;
}

#pragma mark - Xcode Interactive

- (void)openRepo:(NSString *)repo withPath:(NSString *)path {
    NSString *secureBaseUrl = [NSString stringWithFormat:@"https://%@", repo];
    NSString *url = [NSString stringWithFormat:@"%@%@", secureBaseUrl, path];
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[url]];
}

- (void)showMessage:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText: message];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}

#pragma mark - Git Utils

- (NSString *)lastestCommitHash {
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

#pragma mark - Clear Default Repo 

- (void)clearDefaultRepo:(id)sender {
    NSString *defaultRepo = [self defaultRepo];
    if (defaultRepo == nil) {
        [self showMessage:@"There's no default repo setting."];
    } else {
        [self removeDefaultRepo];
        [self showMessage:[NSString stringWithFormat:@"Succeed to clear current default repo(%@) setting. In the next time to open blame in github, will ask you to select new default repo.", defaultRepo]];
    }
}

#pragma mark - Open issues 

- (void)openIssues:(id)sender {
    NSString *remoteRepoPath = [self remoteRepoPath];
    if (!remoteRepoPath) {
        [self showMessage:@"Clould not find remote repo path"];
        return;
    }
    [self openIssueAtIndex:0 remoteRepoPath:remoteRepoPath];
}

- (void)openIssueAtIndex:(NSInteger)index remoteRepoPath:(NSString *)remoteRepoPath{
    NSMutableString *path = [NSMutableString stringWithFormat:@"/issues"];
    if (index > 0) {
        [path appendFormat:@"/%ld", index];
    }
    [self openRepo:remoteRepoPath withPath:path];
}

#pragma mark - Open PRs

- (void)openPRs:(id)sender {
    NSString *remoteRepoPath = [self remoteRepoPath];
    if (!remoteRepoPath) {
        [self showMessage:@"Clould not find remote repo path"];
        return;
    }
    [self openPRAtIndex:0 remoteRepoPath:remoteRepoPath];
}

- (void)openPRAtIndex:(NSInteger)index remoteRepoPath:(NSString *)remoteRepoPath{
    NSString *path;
    if (index > 0) {
        path = [NSString stringWithFormat:@"/pull/%ld", index];
    } else {
        path = @"/pulls";
    }
    [self openRepo:remoteRepoPath withPath:path];
}

#pragma mark - Open History

- (void)openHistory:(id)sender {
    NSString *remoteRepoPath = [self remoteRepoPath];
    if (!remoteRepoPath) {
        return;
    }
    
    NSString *commitHash = [self lastestCommitHash];
    if (!commitHash) {
        return;
    }
    
    NSURL *activeDocumentURL = [self activeDocument];
    NSString *filenameWithPathInCommit = [self filenameWithPathInCommit:commitHash forActiveDocumentURL:activeDocumentURL];
    if (!filenameWithPathInCommit) {
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"/commits/%@/%@",
                              commitHash, filenameWithPathInCommit];
    [self openRepo:remoteRepoPath withPath:path];
}

@end
