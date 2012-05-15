#import <UIKit/UIKit.h>
#import "Constants.h"

@interface MainIconView : UIView <UIGestureRecognizerDelegate>{
	CGRect contentBaseFrame;
	
	CGPoint touchPoint;
	id delegage;
}


@property(assign) id delegate;


@end

@protocol FrienDouIconViewDelegate
@optional

-(void)iconButtonPress;

-(void)FrienDouIconButtonDown;
-(void)NoteDouIconButtonDown;


- (void) fingerHonMoved: (float) distance;
- (void) fingerVonMoved: (float) distance;
- (void) endTouch;
- (void) endMove;
@end