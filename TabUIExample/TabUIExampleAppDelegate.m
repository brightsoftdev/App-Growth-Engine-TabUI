#import "TabUIExampleAppDelegate.h"
#import "TabUIExampleViewController.h"
#import "HookMainWindow.h"

@implementation TabUIExampleAppDelegate


@synthesize window=_window;
@synthesize viewController=_viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
     
    [TestFlight takeOff:@"your-token-here"];
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    [[HookMainWindow sharedHookMainWindow] initWithWindow:self.window appKey:@"your-key-here" multiplayer:NO nativeInvite:YES];
    
    [[HookMainWindow sharedHookMainWindow] initDiscover];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
    if ([HookMainWindow sharedHookMainWindow].needRefresh) {
        [[HookMainWindow sharedHookMainWindow] initDiscover];
    }
    */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

@end

