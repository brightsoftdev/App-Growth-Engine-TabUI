#import "TabUIExampleViewController.h"
#import "HookMainWindow.h"

@implementation TabUIExampleViewController

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction) toggle:(id)sender {
    if (sender == multiplayer) {
        [HookMainWindow sharedHookMainWindow].multiplayer = multiplayer.on;
    }
    if (sender == nativeInvite) {
        [HookMainWindow sharedHookMainWindow].nativeInvite = nativeInvite.on;
    }
    [[HookMainWindow sharedHookMainWindow] resetPref];
}

#pragma mark - View lifecycle

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	multiplayer.on = [HookMainWindow sharedHookMainWindow].multiplayer;
    nativeInvite.on = [HookMainWindow sharedHookMainWindow].nativeInvite;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    // return (interfaceOrientation == UIInterfaceOrientationPortrait);
    
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return NO;
    } else {
        return YES;
    }
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [[HookMainWindow sharedHookMainWindow] adjustOrientation];
}


@end
