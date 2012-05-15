#import "MainIconView.h"

@implementation MainIconView

@synthesize delegate;


#define FrienDouIconButtonTag 0x10001
#define NoteIconButtonTag 0x10002
#define HiddenIconButtonTag 010003

#define FrienDouNumViewTag 0x10004
#define NoteNumViewTag 0x10005


- (id)initWithFrame:(CGRect)frame 
{    
    self = [super initWithFrame:frame];
    if (self) 
	{
		contentBaseFrame = frame;
        // Initialization code.
		//[self setBackgroundColor:[UIColor redColor]];
		//按钮
		UIImage *img = nil;
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (interfaceOrientation == UIInterfaceOrientationPortrait) {
            img = [UIImage imageNamed:@"hook_icon.png"];
        } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            img = [UIImage imageNamed:@"hook_icon1.png"];
        } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            img = [UIImage imageNamed:@"hook_icon2.png"];
        } else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            img = [UIImage imageNamed:@"hook_icon3.png"];
        }
		UIButton *f_btn = [UIButton buttonWithType:UIButtonTypeCustom];
		[f_btn setFrame:CGRectMake(0, 0, img.size.width, img.size.height)];
		[f_btn setBackgroundImage:img forState:UIControlStateNormal];
		
		[f_btn addTarget:self action:@selector(iconButtonPress:) forControlEvents:UIControlEventTouchUpInside];
		[f_btn addTarget:self action:@selector(iconButtonDown:) forControlEvents:UIControlEventTouchDown];
		f_btn.tag = FrienDouIconButtonTag;
		[self addSubview:f_btn];
		
		//页面大小
		CGRect newframe = CGRectMake(frame.origin.x, frame.origin.y, f_btn.frame.size.width, f_btn.frame.size.height);// + n_btn.frame.size.height
		[self setFrame:newframe];
		
		[self bringSubviewToFront:f_btn];
		//手势监听
		UIPanGestureRecognizer *pinGesture = [[UIPanGestureRecognizer alloc] initWithTarget: self action: @selector(userPinned:)];
		pinGesture.delegate = self;
		[self addGestureRecognizer: pinGesture];
		[pinGesture release];
		
		/*
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
		longPressRecognizer.allowableMovement = 60;
		[self addGestureRecognizer:longPressRecognizer];        
		[longPressRecognizer release];
		*/
    }
    return self;
}

/*
- (void) adjustOrientation {
    UIImage *img = nil;
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        NSLog(@"portrait icon");
        img = [UIImage imageNamed:@"hook_icon.png"];
    } else {
        NSLog(@"landscape icon");
        img = [UIImage imageNamed:@"hook_icon1.png"];
    }
    UIButton *f_btn = (UIButton *) [self viewWithTag:FrienDouIconButtonTag];
    [f_btn setFrame:CGRectMake(0, 0, img.size.width, img.size.height)];
    [f_btn setBackgroundImage:img forState:UIControlStateNormal];
}
*/

-(void)iconButtonDown:(id)sender
{
	UIButton *btn = (UIButton *)sender;
	if (btn.tag == FrienDouIconButtonTag) 
	{		
		if ([self.delegate respondsToSelector: @selector(FrienDouIconButtonDown)]) {
			[self.delegate FrienDouIconButtonDown];
		}
	}
}
-(void)iconButtonPress:(id)sender
{
	UIButton *btn = (UIButton *)sender;
	if (btn.tag == FrienDouIconButtonTag)
	{
		//消息数
		UIImageView *badgeView = (UIImageView *)[self viewWithTag:FrienDouNumViewTag];
		if (badgeView) {
			//[badgeView removeFromSuperview];
		}
		if ([self.delegate respondsToSelector: @selector(iconButtonPress)]) {
			[self.delegate iconButtonPress];
		}
	}	
}

/*
-(void)handleLongPress:(UIGestureRecognizer*)gestureRecognizer
{
	if ([gestureRecognizer state] == UIGestureRecognizerStateBegan)
	{
		//[self setBackgroundColor:[UIColor blackColor]];
		UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *) gestureRecognizer;
		CGPoint translatePoint = [panGesture locationInView: self.window];
		touchPoint = translatePoint;
	}
	else if([gestureRecognizer state] == UIGestureRecognizerStateEnded) 
	{
		if ([self.delegate respondsToSelector: @selector(endMove)]) {
			[self.delegate endMove];
		}
	}
	else 
	{
		UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *) gestureRecognizer;
		CGPoint translatePoint = [panGesture locationInView: self.window];
		//NSLog(@"aaaaaaa   == %f",translatePoint.y);
		//if ([self.delegate respondsToSelector: @selector(fingerHonMoved:)]) {
			//[self.delegate fingerVonMoved: translatePoint.y];
		//}
		CGRect fframe = self.frame;
		int offsety = touchPoint.y - translatePoint.y;//向上拉为正 向下拉为负
		fframe.origin.y -= offsety;
		if (fframe.origin.y <= 20) 
		{
			fframe.origin.y = 20;
		}
		else  if(fframe.size.height + fframe.origin.y > self.window.frame.size.height)
		{
			fframe.origin.y = self.window.frame.size.height - fframe.size.height;
		}
		[self setFrame:fframe];
		touchPoint = translatePoint;
	}

}
*/

/**
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touchesBegan");
	//获取触摸点
	[self performSelector:@selector(longPressMethod) withObject:nil afterDelay:2.0];
	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"touchesCancelled");
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longPressMethod) object:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	NSLog(@"touchesEnded");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longPressMethod) object:nil];
	
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	NSLog(@"touchesMoved");
	if (!hasLongPress)
	{
		 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longPressMethod) object:nil];
	}
}

-(void)longPressMethod
{
	NSLog(@"longPressMethod");
	hasLongPress = YES;
	[self setBackgroundColor:[UIColor blueColor]];
}
***/

- (void) userPinned: (UIGestureRecognizer *) gesture {
    UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *) gesture;
    if (gesture.state == UIGestureRecognizerStateEnded) 
	{
		NSLog(@"status == UIGestureRecognizerStateEnded");
		if ([self.delegate respondsToSelector: @selector(endTouch)]) {
			[self.delegate endTouch];
		}
    }
    else 
	{
		//[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longPressMethod) object:nil];
		CGPoint translatePoint = [panGesture translationInView: self];
        
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
		    if ([self.delegate respondsToSelector: @selector(fingerHonMoved:)]) {
			    [self.delegate fingerHonMoved: translatePoint.x];
            }
        }
        if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		    if ([self.delegate respondsToSelector: @selector(fingerVonMoved:)]) {
			    [self.delegate fingerVonMoved: translatePoint.y];
            }
        }
	}
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    [super dealloc];
}


@end
