#import "RecommendsController.h"
#import <QuartzCore/QuartzCore.h>
#import "HookMainWindow.h"
#import "JSON.h"
#import "ContactsController.h"
#import "Discoverer.h"
#import "Lead.h"
#import "NameController.h"

@implementation RecommendsController

#define LoadingViewTag 0x1364

@synthesize entriesView;
@synthesize sendNow;


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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([Discoverer agent].leads != nil) {
        return [[Discoverer agent].leads count] + 1;
    } else {
        return 1;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50.0f;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Referrals"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Referrals"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *subView in cell.contentView.subviews) {
		[subView removeFromSuperview];
	}
	cell.imageView.image = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;
    
	if (indexPath.row >= [[Discoverer agent].leads count]) {
		UIImage *icon = nil;
		cell.textLabel.text = @"Contacts";
        icon = [UIImage imageNamed:@"maillist_icon.png"];
		cell.detailTextLabel.text = nil;
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = icon;
	} else {
        Lead *lead = (Lead *)[[Discoverer agent].leads objectAtIndex:indexPath.row];
        cell.textLabel.text = lead.name;
        // cell.detailTextLabel.text = lead.phone;
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
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.row >= [[Discoverer agent].leads count]){
        ContactsController *contacts = [[ContactsController alloc] initWithNibName:@"ContactsController" bundle:nil];
        contacts.sendNow = sendNow;
        [self.navigationController pushViewController:contacts animated:YES];
        [contacts release];
	} else {
        Lead *lead = [[Discoverer agent].leads objectAtIndex:indexPath.row];
        if (lead.selected) {
            lead.selected = NO;
        } else {
            lead.selected = YES;
        }
    }
    
    [entriesView reloadData];
}

- (IBAction) refresh: (id) sender {
    [[HookMainWindow sharedHookMainWindow] initDiscover];
}

- (IBAction) refer: (id) sender {
    if (![MFMessageComposeViewController canSendText]) {
        // force sendNow on iPad and iPod Touch
        sendNow = YES;
    }
    [self sendReferral];
}

- (void) sendReferral {
    phones = [[NSMutableArray arrayWithCapacity:16] retain];
    for (Lead *lead in [Discoverer agent].leads) {
        if (lead.selected) {
            [phones addObject:lead.phone];
        }
    }
    if ([phones count] > 0) {
        self.navigationItem.rightBarButtonItem.title = @"Wait ...";
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        NSString *name = [HookMainWindow findName];
        if (sendNow && name == nil) {
            [[HookMainWindow sharedHookMainWindow] displayNameSheet:phones];
        } else {
            if (name == nil) {
                [[Discoverer agent] newReferral:phones withMessage:inviteMsgTemplateNoName useVirtualNumber:sendNow];
            } else {
                [[Discoverer agent] newReferral:phones withMessage:[NSString stringWithFormat:inviteMsgTemplate, name] useVirtualNumber:sendNow];
            }
        }
        
    } else {
        UIAlertView* alert = [[UIAlertView alloc] init];
        alert.title = @"Please select referral contacts";
        alert.message = @"Please select a few contacts you would like to refer.";
        [alert addButtonWithTitle:@"Dismiss"];
        alert.cancelButtonIndex = 0;
        [alert show];
        [alert release];
    }
}


- (void) showReferralMessage {
    self.navigationItem.rightBarButtonItem.title = @"Send";
    self.navigationItem.rightBarButtonItem.enabled = YES;
	
    if (!sendNow && [MFMessageComposeViewController canSendText]) {
		[[HookMainWindow sharedHookMainWindow] displayArraySMSComposerSheet:phones msg:[Discoverer agent].referralMessage];
        
    } else if (sendNow) {
        UIAlertView* alert = [[UIAlertView alloc] init];
        alert.title = @"Done";
        alert.message = @"An invite has been sent to your selected contact via SMS.";
        [alert addButtonWithTitle:@"Dismiss"];
        alert.cancelButtonIndex = 0;
        [alert show];
        [alert release];
    }
    
    [HookMainWindow sharedHookMainWindow].needRefresh = YES;
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = inviteTabLabel;
    self.navigationItem.rightBarButtonItem = BARBUTTON (@"Send", UIBarButtonItemStyleDone, @selector(refer:));
    self.navigationItem.leftBarButtonItem = SYSBARBUTTON  (UIBarButtonSystemItemRefresh, @selector(refresh:));
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.sendNow = ![HookMainWindow sharedHookMainWindow].nativeInvite;
    [entriesView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReferralMessage) name:@"HookNewReferralComplete" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
-(void)initRecommends
{
	NSBundle *bundle = [NSBundle mainBundle]; 
	NSString *filePath = [bundle pathForResource:@"addressbook" ofType:@"json"];
	NSString *str = [NSString stringWithContentsOfFile:filePath];
	NSArray *array = [str JSONValue];
	recommends = [array retain];
	
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
