#import "HookMainWindow.h"
#import <AddressBook/AddressBook.h>
#import <CoreLocation/CLLocationManager.h>
#import <QuartzCore/QuartzCore.h>
#import "Discoverer.h"
#import "InstallsController.h"
#import "ContactsController.h"
#import "RecommendsController.h"
#import "NameController.h"
#import "JSON.h"
#import "SVProgressHUD.h"

#define MenuOriginX 31//16
#define MenuWidth   297//282



static HookMainWindow* __Window;

@implementation HookMainWindow
@synthesize myWindow;
@synthesize multiplayer;
@synthesize nativeInvite;
@synthesize needRefresh;

//@synthesize coordinate;
#define LoginViewTag 0x3623
#define LoadingViewTag 0x3624
#define MaskViewTag 0x50001

+ (HookMainWindow*)sharedHookMainWindow {
	@synchronized(self) {
		if(!__Window) {
			__Window = [[[self class] alloc] init];
		}
	}
	
	return __Window;
}

- (id)init {
	if((self = [super init])) {
	}
	
	return self;
}

-(void)initWithWindow:(UIWindow *)window appKey:(NSString *)appKey multiplayer:(BOOL) m nativeInvite:(BOOL) n {

	myWindow = window;
	[Discoverer activate:appKey];
    multiplayer = m;
    nativeInvite = n;
    needRefresh = YES;
	[self initAppView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoverComplete) name:@"HookDiscoverComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoverNoChange) name:@"HookDiscoverNoChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryComplete) name:@"HookQueryOrderComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryFailed) name:@"HookQueryOrderFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verifyComplete) name:@"HookVerifyDeviceComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verificationStatusYes) name:@"HookDeviceVerified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verificationStatusNo) name:@"HookDeviceNotVerified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryInstallsComplete) name:@"HookQueryInstallsComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryInstallsFailed) name:@"HookQueryInstallsFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryReferralComplete) name:@"HookQueryReferralComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryReferralFailed) name:@"HookQueryReferralFailed" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkError) name:@"HookNetworkError" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notSmsDevice) name:@"HookNotSMSDevice" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verificationSMSSent) name:@"HookVerificationSMSSent" object:nil];
	
	BOOL res = [self checkVerifyDevice];
	if (!res) 
	{
		[[Discoverer agent] verifyDevice:ExternalNav forceSms:NO userName:nil];
	}
	else 
	{
		if ([[Discoverer agent] discover]) {
            [self showLoadingViewInTab];
        }
	}

}


-(void)initAppView {
	RecommendsController *recommends = [[RecommendsController alloc] initWithNibName:@"RecommendsController" bundle:nil];
    // recommends.sendNow = !nativeInvite;
	UITabBarItem *customItem3 = [[UITabBarItem alloc] initWithTitle:inviteTabLabel image:[UIImage imageNamed:@"item_icon1.png"] tag:3];
    UINavigationController *recommendsNav = [[UINavigationController alloc] initWithRootViewController:recommends];
	recommendsNav.tabBarItem = customItem3;
	
	InstallsController *installs = [[InstallsController alloc] initWithNibName:@"InstallsController" bundle:nil];
    // installs.viewOnly = !multiplayer;
    UITabBarItem *customItem2 = nil;
    if (multiplayer) {
	    customItem2 = [[UITabBarItem alloc] initWithTitle:playWithFriendsTabLabel image:[UIImage imageNamed:@"item_icon2.png"] tag:2];
    } else {
        customItem2 = [[UITabBarItem alloc] initWithTitle:friendsTabLabel image:[UIImage imageNamed:@"item_icon2.png"] tag:2];
    }
    UINavigationController *installsNav = [[UINavigationController alloc] initWithRootViewController:installs];
	installsNav.tabBarItem = customItem2;
    
    mainTabBar = [[[UITabBarController alloc] init] retain];
	mainTabBar.viewControllers = [NSArray arrayWithObjects:recommendsNav,installsNav,nil];
	mainTabBar.selectedIndex = 0;
    
    CGRect nFrame = mainTabBar.view.frame;
    nFrame.origin.x = myWindow.frame.size.width;
    nFrame.size.width = MainViewWidth;
    if ([UIApplication sharedApplication].statusBarHidden == NO) {
        int barHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        nFrame.origin.y = barHeight;
        nFrame.size.height = myWindow.frame.size.height - barHeight;
    }
	[mainTabBar.view setFrame:nFrame];
    
	[myWindow addSubview:mainTabBar.view];
    
    iconView = [[[MainIconView alloc] initWithFrame:CGRectMake(MenuWidth, 217, myWindow.frame.size.width - MenuWidth, 46)] retain];
	iconView.delegate = self;
	[myWindow addSubview:iconView];
	iconViewBaseFrame = iconView.frame;
    
	ExternalNav = [[UINavigationController alloc] initWithRootViewController:nil];
	[ExternalNav.view setBackgroundColor:[UIColor redColor]];
	ExternalNav.view.alpha = 0.0;
	[ExternalNav setNavigationBarHidden: YES animated: NO];
    [myWindow addSubview: ExternalNav.view];
}

- (void) adjustOrientation {
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        
        [mainTabBar.view setTransform: CGAffineTransformMakeRotation(-M_PI/2)];
        
        CGRect nFrame = mainTabBar.view.frame;
        
        if ([UIApplication sharedApplication].statusBarHidden == NO) {
            nFrame.origin.x = 20;
            nFrame.size.width = 300;
        } else {
            nFrame.origin.x = 0;
            nFrame.size.width = 320;
        }
        nFrame.size.height = 320;
        nFrame.origin.y = -400;
        [mainTabBar.view setFrame:nFrame];
        
        
        [iconView removeFromSuperview];
        iconView = [[[MainIconView alloc] initWithFrame:CGRectMake(137, 0, 46, 23)] retain];
        iconView.delegate = self;
        [myWindow addSubview:iconView];
        iconViewBaseFrame = iconView.frame;
        
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        
        [mainTabBar.view setTransform: CGAffineTransformMakeRotation(M_PI/2)];
        
        CGRect nFrame = mainTabBar.view.frame;
        
        if ([UIApplication sharedApplication].statusBarHidden == NO) {
            nFrame.origin.x = 0;
            nFrame.size.width = 300;
        } else {
            nFrame.origin.x = 20;
            nFrame.size.width = 320;
        }
        nFrame.size.height = 320;
        nFrame.origin.y = 500;
        [mainTabBar.view setFrame:nFrame];
        // [mainTabBar.view setTransform: CGAffineTransformMakeRotation(M_PI/2)];
        
        [iconView removeFromSuperview];
        iconView = [[[MainIconView alloc] initWithFrame:CGRectMake(137, 457, 46, 23)] retain];
        iconView.delegate = self;
        [myWindow addSubview:iconView];
        iconViewBaseFrame = iconView.frame;
        
    } else if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        
        [mainTabBar.view setTransform: CGAffineTransformMakeRotation(0)];
        
        CGRect nFrame = mainTabBar.view.frame;
        nFrame.origin.x = myWindow.frame.size.width;
        nFrame.size.width = MainViewWidth;
        if ([UIApplication sharedApplication].statusBarHidden == NO) {
            nFrame.origin.y = 20;
            nFrame.size.height = myWindow.frame.size.height - 20;
        }
        [mainTabBar.view setFrame:nFrame];
        
        [iconView removeFromSuperview];
        iconView = [[[MainIconView alloc] initWithFrame:CGRectMake(MenuWidth, 217, myWindow.frame.size.width - MenuWidth, 46)] retain];
        iconView.delegate = self;
        [myWindow addSubview:iconView];
        iconViewBaseFrame = iconView.frame;

    } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        
        // not supported
        
    }
    
    UINavigationController *nav0 = [[mainTabBar viewControllers] objectAtIndex:0];
	RecommendsController *recommands = (RecommendsController *)[[nav0 viewControllers] objectAtIndex:0];
	[recommands.entriesView reloadData];
    
    UINavigationController *nav1 = [[mainTabBar viewControllers] objectAtIndex:1];
	InstallsController *installs = (InstallsController *)[[nav1 viewControllers] objectAtIndex:0];
    [installs.entriesView reloadData];
}

/*
- (void) addLoadingView {
	UIView *loadingView = [[UIView alloc] initWithFrame:myWindow.bounds];
	loadingView.tag = LoadingViewTag;
	
	UILabel *bglabel = [[UILabel alloc] initWithFrame:CGRectMake((loadingView.frame.size.width - 200.0f)/2, 170.0f, 200.0f, 100.0f)];
	bglabel.backgroundColor = [UIColor blackColor];
	bglabel.alpha = 0.55;
	bglabel.layer.masksToBounds = YES;
	bglabel.layer.cornerRadius = 5;
	bglabel.layer.borderWidth = 2;
	bglabel.layer.borderColor = [[UIColor grayColor] CGColor];
	[loadingView addSubview:bglabel];
	[bglabel release];
	UIActivityIndicatorView *_activityView = [[UIActivityIndicatorView alloc]
											  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	_activityView.frame = CGRectMake((loadingView.frame.size.width - 24.0f)/2, 200.0f, 24.0f, 24.0f );
	[_activityView startAnimating];
	[loadingView addSubview:_activityView];
	[_activityView release];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 240, loadingView.frame.size.width, 20)];
	[label setBackgroundColor:[UIColor clearColor]];
	[label setText:@"Wait ..."];
	[label setTextColor:[UIColor whiteColor]];
	[label setFont:[UIFont boldSystemFontOfSize:15.0f]];
	label.textAlignment = UITextAlignmentCenter;
	[loadingView addSubview:label];
	[label release];
	
	[myWindow addSubview:loadingView];
	[loadingView release];
	
}
-(void) removeLoadingView {
	UIView *LoadingView = [myWindow viewWithTag:LoadingViewTag];
	[LoadingView removeFromSuperview];
}
*/

-(void) showLoadingViewInTab {
    [SVProgressHUD showInView:[mainTabBar selectedViewController].view status:@"Loading ..."];
    
    // UINavigationController *recommendsNav = [[mainTabBar viewControllers] objectAtIndex:0];
    // RecommendsController *recommendsControl = (RecommendsController *)[[recommendsNav viewControllers] objectAtIndex:0];
    
    // UINavigationController *installsNav = [[mainTabBar viewControllers] objectAtIndex:1];
    // InstallsController *installsControl = (InstallsController *)[[installsNav viewControllers] objectAtIndex:0];
}

/*
-(void) showLoadingViewInTabIfNeeded {
    if ([Discoverer agent].leads == nil || [[Discoverer agent].leads count] == 0) {
        UINavigationController *recommendsNav = [[mainTabBar viewControllers] objectAtIndex:0];
        RecommendsController *recommendsControl = (RecommendsController *)[[recommendsNav viewControllers] objectAtIndex:0];
        [SVProgressHUD showInView:recommendsControl.view status:@"Loading ..."];
    }
    if ([Discoverer agent].installs == nil || [[Discoverer agent].installs count] == 0) {
        UINavigationController *installsNav = [[mainTabBar viewControllers] objectAtIndex:1];
        InstallsController *installsControl = (InstallsController *)[[installsNav viewControllers] objectAtIndex:0];
        [SVProgressHUD showInView:installsControl.view status:@"Loading ..."];
    }
}
*/

- (void) resetPref {
    UINavigationController *recommendsNav = [[mainTabBar viewControllers] objectAtIndex:0];
    RecommendsController *recommendsControl = (RecommendsController *)[[recommendsNav viewControllers] objectAtIndex:0];
    recommendsControl.sendNow = !nativeInvite;
    // CANNOT do viewWillAppear here -- it would double register the notification event
    
    UINavigationController *installsNav = [[mainTabBar viewControllers] objectAtIndex:1];
    InstallsController *installsControl = (InstallsController *)[[installsNav viewControllers] objectAtIndex:0];
    installsControl.viewOnly = !multiplayer;
    [installsControl viewWillAppear:NO];
}


-(BOOL) checkVerifyDevice {
	NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
	NSString *path=[paths objectAtIndex:0];
	NSString *filename=[path stringByAppendingPathComponent:@"Verify.plist"]; 
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:filename]) 
	{
		return YES;
	}
	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1],@"Verify",nil];
	[dic writeToFile:filename atomically:YES];
	return NO;
	
}

-(void)initDiscover {
    if ([Discoverer agent].installCode == nil) {
        // we will wait until the /newverify to return before requesting discover
        return;
    }
    
    NSLog(@"Start discovery");
    if ([[Discoverer agent] discover]) {
        [self showLoadingViewInTab];
    }
}
- (void) verifyComplete 
{
	//[self removeLoadingView];
	[self initDiscover];
}

- (void) verificationStatusYes 
{
	// [[Discoverer agent] discover];
    [self initDiscover];
}

- (void) verificationStatusNo 
{
	[[Discoverer agent] queryVerifiedStatus];
}

- (void) discoverComplete {
    NSLog(@"discoverComplete");
    [self performSelector:@selector(initQueryOrder) withObject:nil afterDelay:10.0f];
    needRefresh = NO;
}

- (void) discoverNoChange {
    NSLog(@"discoverNoChange");
    [self initQueryOrder];
    needRefresh = NO;
}

-(void)initQueryOrder {
    NSLog(@"initQueryOrder");
	// [self removeLoadingView];
	[[Discoverer agent] queryOrder];
	[[Discoverer agent] queryInstalls:@"FORWARD"];
	
    /*
	UINavigationController *recommendsNav = [[mainTabBar viewControllers] objectAtIndex:0];
	RecommendsController *recommendsControl = (RecommendsController *)[[recommendsNav viewControllers] objectAtIndex:0];
	[recommendsControl addLoadingView];
	
	UINavigationController *installsNav = [[mainTabBar viewControllers] objectAtIndex:1];
	InstallsController *installsControl = (InstallsController *)[[installsNav viewControllers] objectAtIndex:0];
	[installsControl addLoadingView];
    */
}
    
- (void) queryComplete 
{
    NSLog(@"queryComplete");
	UINavigationController *nav = [[mainTabBar viewControllers] objectAtIndex:0];
	RecommendsController *control = (RecommendsController *)[[nav viewControllers] objectAtIndex:0];
    [SVProgressHUD dismiss];
	[control.entriesView reloadData];
}
- (void) queryFailed 
{    
	UINavigationController *nav = [[mainTabBar viewControllers] objectAtIndex:0];
	RecommendsController *control = (RecommendsController *)[[nav viewControllers] objectAtIndex:0];
	[SVProgressHUD dismiss];
	[control.entriesView reloadData];
	
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Finished";
	alert.message = [NSString stringWithFormat:@"Hook Mobile server encountered a problem processing your addressbook: %@", [Discoverer agent].errorMessage];
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
	[alert release];
}
- (void) queryInstallsComplete {
    NSLog(@"queryInstallsComplete");
	UINavigationController *nav = [[mainTabBar viewControllers] objectAtIndex:1];
	InstallsController *control = (InstallsController *)[[nav viewControllers] objectAtIndex:0];
	[control.entriesView reloadData];
	[SVProgressHUD dismiss];
}

- (void) queryInstallsFailed 
{    
	UINavigationController *nav = [[mainTabBar viewControllers] objectAtIndex:1];
	InstallsController *control = (InstallsController *)[[nav viewControllers] objectAtIndex:0];
	[control.entriesView reloadData];
	[SVProgressHUD dismiss];
	
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Finished";
    alert.message = [NSString stringWithFormat:@"Hook Mobile server encountered a problem processing the installs database: %@", [Discoverer agent].errorMessage];
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
	[alert release];
}
- (void) queryReferralComplete {
    NSLog(@"referral done");
   // [self.navigationController pushViewController:referralsController animated:YES];
}

- (void) queryReferralFailed {
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Finished";
	alert.message = [NSString stringWithFormat:@"Hook Mobile server encountered a problem processing the referrals database: %@", [Discoverer agent].errorMessage];
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
	[alert release];
}

- (void) networkError {
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Network required";
	alert.message = @"Network is required to perform this function. Please try again later.";
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
	[alert release];
    
    UINavigationController *nav0 = [[mainTabBar viewControllers] objectAtIndex:0];
	RecommendsController *recommands = (RecommendsController *)[[nav0 viewControllers] objectAtIndex:0];
	[recommands.entriesView reloadData];
    
    UINavigationController *nav1 = [[mainTabBar viewControllers] objectAtIndex:1];
	InstallsController *installs = (InstallsController *)[[nav1 viewControllers] objectAtIndex:0];
	[installs.entriesView reloadData];
	
    [SVProgressHUD dismiss];
}

- (void) notSmsDevice 
{
	// [self performSelector:@selector(removeLoadingView) withObject:nil afterDelay:2.0f];
}
-(void)verificationSMSSent
{
	// [self addLoadingView];
    [[Discoverer agent] queryVerifiedStatus];
}

/*
-(void) newReferralComplete {
    UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Done";
	alert.message = @"An invite has been sent to your selected contacts via SMS.";
	[alert addButtonWithTitle:@"Dismiss"];
	alert.cancelButtonIndex = 0;
	[alert show];
	[alert release];
}
*/

















#pragma mark-- NavigationViewControllerDelegate methods

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
}
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{

}

#pragma mark-- Window methods
- (void) showFullWindow: (BOOL) animated {
    
	if (animated) {
        NSLog(@"showFullWindow animated");
		[UIView beginAnimations: nil context:nil];
		[UIView setAnimationDuration: 0.3];
		[UIView setAnimationDelegate: self];
		[UIView setAnimationDidStopSelector: @selector(windowAnimationEnd)];
		CGRect iconFrame = iconViewBaseFrame;
		iconFrame.origin.x = -iconFrame.size.width;
		iconView.frame = iconFrame;
		
		CGRect nFrame = mainTabBar.view.frame;
		nFrame.origin.x = 0;
		mainTabBar.view.frame = nFrame;
		
		[UIView commitAnimations];
	} else {
        NSLog(@"showFullWindow NOT animated");
		CGRect iconFrame = iconViewBaseFrame;
		iconFrame.origin.x = -iconFrame.size.width;
		iconView.frame = iconFrame;
		
		CGRect nFrame = mainTabBar.view.frame;
		nFrame.origin.x = 0;
		mainTabBar.view.frame = nFrame;
		[self performSelector:@selector(windowAnimationEnd)];
	}
}
- (void) showWindow: (BOOL) show {
	NSLog(@"showWindow");
    
	windowActive = show;
	
    [UIView beginAnimations: nil context:nil];
    [UIView setAnimationDuration: 0.3];
    [UIView setAnimationDelegate: self];
    [UIView setAnimationDidStopSelector: @selector(windowAnimationEnd)];
    CGRect iconFrame = iconViewBaseFrame;
    CGRect nFrame = mainTabBar.view.frame;
    if (show) 
	{
		[myWindow resignKeyWindow];
        
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (interfaceOrientation == UIInterfaceOrientationPortrait) {
		    iconFrame.origin.x = MenuOriginX;
            nFrame.origin.x = iconFrame.origin.x + iconFrame.size.width;
        } else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            iconFrame.origin.y = 320;
            // nFrame.origin.y = iconFrame.origin.y + iconFrame.size.height;
            if ([UIApplication sharedApplication].statusBarHidden == NO) {
                nFrame.origin.x = 20;
                nFrame.size.width = 300;
            } else {
                nFrame.origin.x = 0;
                nFrame.size.width = 320;
            }
            nFrame.origin.y = 0;
        } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            iconFrame.origin.y = 137;
            // nFrame.origin.y = iconFrame.origin.y + iconFrame.size.height;
            if ([UIApplication sharedApplication].statusBarHidden == NO) {
                nFrame.origin.x = 0;
                nFrame.size.width = 300;
            } else {
                nFrame.origin.x = 20;
                nFrame.size.width = 320;
            }
            nFrame.origin.y = 160;
        } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            iconFrame.origin.x = MenuOriginX;
        }
    }
	else 
	{
		[myWindow makeKeyWindow];
        
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (interfaceOrientation == UIInterfaceOrientationPortrait) {
		    iconFrame.origin.x = MenuWidth;
            nFrame.origin.x = iconFrame.origin.x + iconFrame.size.width;
        } else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            iconFrame.origin.y = 0;
            if ([UIApplication sharedApplication].statusBarHidden == NO) {
                nFrame.origin.x = 20;
            } else {
                nFrame.origin.x = 0;
            }
            nFrame.origin.y = -400;
        } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            iconFrame.origin.y = 457;
            if ([UIApplication sharedApplication].statusBarHidden == NO) {
                nFrame.origin.x = 0;
            } else {
                nFrame.origin.x = 20;
            }
            nFrame.origin.y = iconFrame.origin.y + iconFrame.size.height;
        } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            iconFrame.origin.x = 320 - MenuWidth;
        }
    }
    iconView.frame = iconFrame;
    mainTabBar.view.frame = nFrame;
    
    [UIView commitAnimations]; 
}
-(void)windowAnimationEnd {
    NSLog(@"windowAnimationEnd");
    
	if (windowActive)
	{
		UIButton *_maskView = (UIButton *)[myWindow viewWithTag:MaskViewTag];
		if (!_maskView) 
		{
			_maskView = [UIButton buttonWithType:UIButtonTypeCustom];
			[_maskView setFrame:myWindow.bounds];
			//_maskView = [[UIView alloc] initWithFrame:myWindow.bounds];
			_maskView.tag = MaskViewTag;
			[_maskView setBackgroundColor:[UIColor blackColor]];
			[_maskView setAlpha:0.0];
			/***
			UIImage *c_img = [LocaleUtils loadPngImage:@"haoyoudou_close"];
			UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
			[btn setFrame:CGRectMake(10, iconView.frame.origin.y + (iconView.frame.size.height - c_img.size.height)/2, c_img.size.width, c_img.size.height)];
			[btn setBackgroundImage:c_img forState:UIControlStateNormal];
			[btn addTarget:self action:@selector(closeWindowButtonPress:) forControlEvents:UIControlEventTouchUpInside];
			[_maskView addSubview:btn];
			***/
			[_maskView addTarget:self action:@selector(closeWindowButtonPress:) forControlEvents:UIControlEventTouchUpInside];
			[myWindow addSubview:_maskView];
			[myWindow bringSubviewToFront:mainTabBar.view];
			[myWindow bringSubviewToFront:iconView];
			[myWindow bringSubviewToFront:ExternalNav.view];
			
			[UIView beginAnimations: nil context:nil];
			[UIView setAnimationDuration: 0.3];
			[_maskView setAlpha:0.7];
			[UIView commitAnimations];
			
		}
		
		[self checkVerifyDevice];
	}
	else 
	{
		UIView *_maskView = [myWindow viewWithTag:MaskViewTag];
		[_maskView removeFromSuperview];
	}

	iconViewBaseFrame = iconView.frame;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self showWindow:NO];
}
-(void)closeWindowButtonPress:(id)sender
{
	[self showWindow:NO];
}
-(void)iconButtonPress
{
	if (!windowActive) {
		[self showWindow:YES];
	}
	else if (windowActive) 
	{
		[self showWindow:NO];
	}
}
-(void)FrienDouIconButtonDown {
    NSLog(@"FrienDouIconButtonDown");
	/*
	CGRect nFrame = mainTabBar.view.frame;
	nFrame.origin.x = iconView.frame.origin.x + iconView.frame.size.width;
	mainTabBar.view.frame = nFrame;
	
	[UIView beginAnimations: nil context:nil];
	[UIView setAnimationDuration: 0.3];
	[mainTabBar.view setAlpha:1.0f];
	[UIView commitAnimations];
    */
}
//纵向滚动
- (void) fingerVonMoved: (float) distance {
    NSLog(@"fingerVonMoved %f", distance);
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGRect iconFrame = iconViewBaseFrame;
    iconFrame.origin.y += distance;
    if (iconFrame.origin.y <= 0) 
	{
        iconFrame.origin.y = 0;
    } 
	else if (iconFrame.origin.y >= myWindow.frame.size.height - iconFrame.size.height) 
	{
        iconFrame.origin.y = myWindow.frame.size.height - iconFrame.size.height;
    }
    iconView.frame = iconFrame;
    
    CGRect nFrame = mainTabBar.view.frame;
    if (interfaceOrientation ==UIInterfaceOrientationLandscapeLeft) {
	    nFrame.origin.y = iconFrame.origin.y - 320;
    } else if (interfaceOrientation ==UIInterfaceOrientationLandscapeRight) {
        nFrame.origin.y = iconFrame.origin.y + iconFrame.size.height;
    }
	mainTabBar.view.frame = nFrame;
}
//横向滚动
- (void) fingerHonMoved: (float) distance  {
    NSLog(@"fingerHonMoved %f", distance);
    
    //[UIView beginAnimations: nil context:nil];
    //[UIView setAnimationDuration: 0.3];
    CGRect iconFrame = iconViewBaseFrame;
    iconFrame.origin.x += distance;
	if (iconFrame.origin.x < MenuOriginX) 
	{
		iconFrame.origin.x = MenuOriginX;
	} 
	else if (iconFrame.origin.x > MenuWidth) 
	{
		iconFrame.origin.x = MenuWidth;
	}
	iconView.frame = iconFrame;
	
	CGRect nFrame = mainTabBar.view.frame;
	nFrame.origin.x = iconFrame.origin.x + iconFrame.size.width;
	mainTabBar.view.frame = nFrame;
}

- (void) endTouch {
    NSLog(@"endTouch");
    
	BOOL show = windowActive;
	if (show)
	{
		if (iconView.frame.origin.x > MenuOriginX ) {
			show = NO;
		}
	}
	else {
		if (iconView.frame.origin.x < 250)
		{
			show = YES;
		}
		else {
			show = NO;
		}

	}
	/**
	if (iconView.frame.origin.x < 250)
	{//拉出的位置小于200点,展开
		if (!windowActive) {
			windowActive = YES;
		}
		//windowActive = !windowActive;
	}
	else {
		windowActive = NO;
	}
	 ***/
	[self showWindow:show];
	/**
	 if (nav.view.frame.origin.x > nav.view.frame.size.width/2) {
	 [self showMenu: YES];
	 menuShown = YES;
	 } else {
	 [self showMenu: NO];
	 menuShown = NO;
	 }
	 ***/
	//NSLog(@"end Touch");
    //contentBaseFrame = nav.view.frame;
}
-(void)endMove {
    NSLog(@"endMove");
	iconViewBaseFrame = iconView.frame;
}






#pragma mark -
#pragma mark Show Mail/SMS picker
-(void) displayArraySMSComposerSheet:(NSArray *)phones msg:(NSString *)msg {
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
	picker.messageComposeDelegate = self;
	picker.recipients = phones;
	picker.body = msg;
	[ExternalNav presentModalViewController:picker animated:YES];
	[picker release];
}
#pragma mark -
#pragma mark Dismiss Mail/SMS view controller
// Dismisses the message composition interface when users tap Cancel or Send. Proceeds to update the 
// feedback message field with the result of the operation.
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller 
				 didFinishWithResult:(MessageComposeResult)result {
	[controller dismissModalViewControllerAnimated:YES];
}

- (void) displayNameSheet:(NSArray *)phones {
    NameController *nameController = [[NameController alloc] initWithNibName:@"NameController" bundle:nil];
    nameController.phones = phones;
    [ExternalNav presentModalViewController:nameController animated:YES];
}


+ (NSString *) findName {
    NSString *name = nil;
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (standardUserDefaults) {
        name = [standardUserDefaults objectForKey:@"name"];
    }
    return name;
}

+ (void) saveName:(NSString *) name {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (standardUserDefaults) {
        [standardUserDefaults setObject:name forKey:@"name"];
        [standardUserDefaults synchronize];
    }
}


@end
