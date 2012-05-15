#import "InstallsController.h"
#import <QuartzCore/QuartzCore.h>
#import "HookMainWindow.h"
#import "JSON.h"
#import "Discoverer.h"
#import "Lead.h"

@implementation InstallsController

#define LoadingViewTag 0x7436
@synthesize entriesView;
@synthesize viewOnly;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if ([Discoverer agent].installs != nil) {
        return [[Discoverer agent].installs count];
    }
	return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Leads"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Leads"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
	for (UIView *subView in cell.contentView.subviews) {
		[subView removeFromSuperview];
	}
	
    Lead *lead = (Lead *)[[Discoverer agent].installs objectAtIndex:indexPath.row];
    cell.textLabel.text = lead.name;
		 
    UIImage *icon = nil;
    if ([lead.osType isEqual:@"android"]) {
        icon = [UIImage imageNamed:@"devicon0.png"];
    }
    else if([lead.osType isEqual:@"ios"])
    {
        icon = [UIImage imageNamed:@"devicon1.png"];
    }
    else 
    {
        icon = [UIImage imageNamed:@"devicon2.png"];
    }
    UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
    if (lead.selected) 
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [iconView setFrame:CGRectMake(tableView.frame.size.width - icon.size.width - 30, 10, icon.size.width, icon.size.height)];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [iconView setFrame:CGRectMake(tableView.frame.size.width - icon.size.width - 10, 10, icon.size.width, icon.size.height)];
    }
    [cell.contentView addSubview:iconView];
    [iconView release];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (viewOnly) {
        [entriesView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        Lead *lead = [[Discoverer agent].installs objectAtIndex:indexPath.row];
        if (lead.selected) {
            lead.selected = NO;
        } else {
            lead.selected = YES;
        }
	    [entriesView reloadData];
    }
}

- (IBAction) play:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] init];
    alert.title = @"Call to Action";
    alert.message = @"Please implement the play method in InstallsController to engage those users for Call-to-Action.";
    [alert addButtonWithTitle:@"Dismiss"];
    alert.cancelButtonIndex = 0;
    [alert show];
    [alert release];
    
}

- (IBAction) refresh: (id) sender {
    [[HookMainWindow sharedHookMainWindow] initDiscover];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.viewOnly = ![HookMainWindow sharedHookMainWindow].multiplayer;
    [entriesView reloadData];
    
    if (viewOnly) {
        self.title = friendsTabLabel;
        self.navigationItem.leftBarButtonItem = SYSBARBUTTON  (UIBarButtonSystemItemRefresh, @selector(refresh:));
    } else {
        self.title = playWithFriendsTabLabel;
	    self.navigationItem.rightBarButtonItem = BARBUTTON (@"Play", UIBarButtonItemStyleDone, @selector(play:));
        self.navigationItem.leftBarButtonItem = SYSBARBUTTON  (UIBarButtonSystemItemRefresh, @selector(refresh:));
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return NO;
    } else {
        return YES;
    }
}

/*
-(void)initInstalls
{
	NSBundle *bundle = [NSBundle mainBundle]; 
	NSString *filePath = [bundle pathForResource:@"addressbook" ofType:@"json"];
	NSString *str = [NSString stringWithContentsOfFile:filePath];
	NSArray *array = [str JSONValue];
	installs = [[NSMutableArray alloc] init];
	for (int i = 0; i < [array count]; i++)
	{
		if (i%2 == 0) {
			NSDictionary *item = [array objectAtIndex:i];
			[installs addObject:item];
		}
	}
	
}
*/

/*
-(void)addLoadingView
{
	UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 100.0f)/2, 170.0f, 100.0f, 60.0f)];
	loadingView.tag = LoadingViewTag;
	loadingView.backgroundColor = [UIColor blackColor];
	loadingView.alpha = 0.55;
	loadingView.layer.masksToBounds = YES;
	loadingView.layer.cornerRadius = 5;
	loadingView.layer.borderWidth = 2;
	loadingView.layer.borderColor = [[UIColor grayColor] CGColor];
	UIActivityIndicatorView *_activityView = [[UIActivityIndicatorView alloc]
											  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	_activityView.frame = CGRectMake((loadingView.frame.size.width - 24.0f)/2, 20.0f, 24.0f, 24.0f );
	[_activityView startAnimating];
	[loadingView addSubview:_activityView];
	[_activityView release];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, loadingView.frame.size.width, 20)];
	[label setBackgroundColor:[UIColor clearColor]];
	[label setText:@"wait ..."];
	[label setTextColor:[UIColor whiteColor]];
	[label setFont:[UIFont boldSystemFontOfSize:15.0f]];
	label.textAlignment = UITextAlignmentCenter;
	[loadingView addSubview:label];
	[label release];
	
	[self.entriesView addSubview:loadingView];
	[loadingView release];
	
}
-(void)removeLoadingView
{
	UIView *LoadingView = [self.entriesView viewWithTag:LoadingViewTag];
    if (LoadingView != nil) {
	    [LoadingView removeFromSuperview];
    }
}
*/

@end
