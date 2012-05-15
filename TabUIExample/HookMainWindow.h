#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "MainIconView.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "Constants.h"

#define MainViewWidth 266

@interface HookMainWindow : NSObject <UINavigationControllerDelegate,MFMessageComposeViewControllerDelegate,MFMailComposeViewControllerDelegate,CLLocationManagerDelegate>{

	UIWindow *myWindow;

	MainIconView *iconView;
	CGRect iconViewBaseFrame;

	UINavigationController *ExternalNav;
	
	UITabBarController *mainTabBar;
    
    BOOL windowActive;
    
	int navBarInitFinish;
    
    BOOL multiplayer;
    BOOL nativeInvite;
    
    // This indicates that the lists need to be refreshed the next time the app becomes active
    BOOL needRefresh;
}

@property (nonatomic,assign) UIWindow *myWindow;
@property (nonatomic) BOOL multiplayer;
@property (nonatomic) BOOL nativeInvite;
@property (nonatomic) BOOL needRefresh;

+ (HookMainWindow *) sharedHookMainWindow;
					
- (void) initWithWindow:(UIWindow *)window appKey:(NSString *)appKey multiplayer:(BOOL) m nativeInvite:(BOOL) n;
- (void) initAppView;
- (void) adjustOrientation;
- (void) resetPref;

- (BOOL) checkVerifyDevice;
- (void) initDiscover;
- (void) initQueryOrder;

// -(void)addLoadingView;
// -(void)removeLoadingView;
// - (void) showLoadingViewInTabIfNeeded;
- (void) showLoadingViewInTab;

- (void) showFullWindow: (BOOL) animated;
- (void) showWindow: (BOOL) show;


- (void) displayArraySMSComposerSheet:(NSArray *)phones msg:(NSString *)msg;
- (void) displayNameSheet:(NSArray *)phones;

+ (NSString *) findName;
+ (void) saveName:(NSString *) name;


@end


