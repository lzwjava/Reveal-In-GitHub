//
//  GithubKitPlugin.m
//  GithubKitPlugin
//
//  Created by lzw on 15/10/22.
//  Copyright © 2015年 lzwjava. All rights reserved.
//

#import "RevealInGithubPlugin.h"
#import <Cocoa/Cocoa.h>

#ifdef DEBUG
#   define LZLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define LZLog(fmt, ...)
#endif

id objc_getClass(const char* name);

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

#pragma mark - Notification

- (void)addNotification{
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
    
    NSMenu *sixToolsMenu = [self githubMenu];
    
    // Create action menu items
    NSMenuItem *openBlameItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Open blame in GitHub" action:@selector(openBlameInGithub:) keyEquivalent:@"c"];
    [openBlameItem setKeyEquivalentModifierMask:NSControlKeyMask];
    
    openBlameItem.target = self;
    [sixToolsMenu addItem:openBlameItem];
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

#pragma mark - Actions

- (void)openBlameInGithub:(id)sender {
    
}


@end
