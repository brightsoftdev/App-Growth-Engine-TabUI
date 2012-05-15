#import "ContactsController.h"
#import <AddressBook/AddressBook.h>
#import <QuartzCore/QuartzCore.h>
#import "HookMainWindow.h"
#import "Discoverer.h"
#import "Lead.h"
#import "NameController.h"

@implementation ContactsController

#define LoadingViewTag 0x3623
@synthesize searchListContent;
@synthesize contactsArray = _contactsArray;
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
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50.0f;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (searchIsActive) {
		return [self.searchListContent count];
	}
	return [self.contactsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Leads"];
    if (cell == nil) {
        //cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Leads"];
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Leads"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	NSDictionary *item = nil;
	if (searchIsActive) {
		item = [self.searchListContent objectAtIndex:indexPath.row];
	}
	else {
		item = [self.contactsArray objectAtIndex:indexPath.row];
	}
	
	NSString *name = [item valueForKey:@"name"];
	NSString *phone = [item valueForKey:@"phone"];
	
	cell.textLabel.text = name;
	cell.detailTextLabel.text = phone;
	/***
	//int platform = [[item valueForKey:@"platform"] intValue];
	UIImage *icon = nil;
	if (platform == 0) {
		icon = [UIImage imageNamed:@"devicon0.png"];
	}
	else if(platform == 1)
	{
		icon = [UIImage imageNamed:@"devicon1.png"];
	}
	else if(platform == 2)
	{
		icon = [UIImage imageNamed:@"devicon2.png"];
	}
	cell.imageView.image = icon;
	****/
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btn setFrame:CGRectMake(0, 0, 60, 30)];
	[btn.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
	[btn setTitle:@"Invite" forState:UIControlStateNormal];
    [btn setTitle:@"Invited" forState:UIControlStateDisabled];
	[btn addTarget:self action:@selector(InviteButtonPress:) forControlEvents:UIControlEventTouchUpInside];
	cell.accessoryView = btn;
	//cell.accessoryType = UITableViewCellAccessoryCheckmark;
    /***
    Lead *lead = (Lead *)[[Discoverer agent].leads objectAtIndex:indexPath.row];
    cell.textLabel.text = lead.name;
    cell.detailTextLabel.text = lead.osType;
    if (lead.selected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    ***/
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [entriesView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)InviteButtonPress:(id)sender {
	NSIndexPath *index = [entriesView indexPathForCell:(UITableViewCell *)[sender superview]];
	NSString *phone = nil;
	if (searchIsActive) {
		NSDictionary *item = [self.searchListContent objectAtIndex:index.row];
		phone = [item valueForKey:@"phone"];
	}
	else {
		NSDictionary *item = [self.contactsArray objectAtIndex:index.row];
		phone = [item valueForKey:@"phone"];
	}
    phone = [[Discoverer agent] formatPhone:phone];
    
    // Alternative
	// [[HookMainWindow sharedHookMainWindow] showSMSPicker:phone msg:@"I thought you might be interested in this app 'AGE SDK', check it out here %link%" inControl:self];
    
    phones = [[NSMutableArray arrayWithCapacity:16] retain];
    [phones addObject:phone];
    
    if (![MFMessageComposeViewController canSendText]) {
        sendNow = YES;
    }
    
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
    
    ((UIButton *)sender).enabled = NO;
    ((UIButton *)sender).alpha = 0.5;
}

- (void) showReferralMessage {
    self.navigationItem.rightBarButtonItem.title = @"Send";
    
    if (!sendNow && [MFMessageComposeViewController canSendText])  {
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
}


#pragma mark -
#pragma mark UISearchBar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)bar
{
	bar.showsCancelButton = YES;
}
- (void)searchBar:(UISearchBar *)sBar textDidChange:(NSString *)searchText
{
	searchIsActive = YES;
	
	if (self.searchListContent == nil) 
	{
		NSMutableArray *array = [[NSMutableArray alloc] init];
		self.searchListContent = array;
		[array release];
	}
	[self.searchListContent removeAllObjects];// First clear the filtered array
	
	NSString *sText = [searchText uppercaseString];//改为小写
	if ([sText length] <= 0) 
	{
		searchIsActive = NO;
		[sBar resignFirstResponder];
		sBar.showsCancelButton = NO;
		[entriesView reloadData];
		return;
	}
	
	for (NSDictionary *item in self.contactsArray)
	{
		NSString *name = [item valueForKey:@"name"];
		NSString *phone = [item valueForKey:@"phone"];
		NSRange range = [name rangeOfString:sText];
		NSRange range1 = [phone rangeOfString:sText];
		int location = range.location;
		int location1 = range1.location;
		if (location != NSNotFound || location1 != NSNotFound)
		{
			[self.searchListContent addObject:item];
		}
		/**
		 else 
		 {
		 range = [phone rangeOfString:sText];
		 location = range.location;
		 
		 if (location != NSNotFound)
		 {
		 [self.searchListContent addObject:item];
		 }
		 }
		 ***/
	}
	
	[entriesView reloadData];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)sBar
{
	sBar.text = @"";
	[sBar resignFirstResponder];
	sBar.showsCancelButton = NO;
	searchIsActive = NO;
	[entriesView reloadData];
}
- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView 
{
	//开始拉动
	if (scrollView == entriesView) 
	{
		/***
		if (self.friendSearchBar) {
			if (self.friendSearchBar.showsCancelButton) {
				//if (searchIsActive) {
				[self.friendSearchBar resignFirstResponder];
				self.friendSearchBar.showsCancelButton = NO;
				if ([self.friendSearchBar.text length] <= 0) {
					searchIsActive = NO;
					[self.friendTableView reloadData];
				}
			}
		}
		 ***/
	}
}

-(void)getAddressPhones
{
	NSMutableArray *temp_array = [[NSMutableArray alloc] init];
	ABAddressBookRef addressBook = ABAddressBookCreate();
	//把所有通讯录记录保存在一个数组中
	CFArrayRef personarray = ABAddressBookCopyArrayOfAllPeople(addressBook);//这是个个人信息的数组的引用
	
	int allrow = CFArrayGetCount(personarray);
	//循环取出一条记录
	for(int i = 0; i<allrow; i++)
	{
		ABRecordRef person=CFArrayGetValueAtIndex(personarray, i);//取出一条记录 
		if (person) 
		{
			//获取名字
			NSString* name = (NSString *)ABRecordCopyCompositeName(person); 
			ABMultiValueRef temps_phones = (ABMultiValueRef) ABRecordCopyValue(person, kABPersonPhoneProperty);
			//电话号码个数
			int nCount = ABMultiValueGetCount(temps_phones);		
			//电话号码
			for(int j = 0;j < nCount;j++)
			{
				NSString *phoneNO = (NSString *)ABMultiValueCopyValueAtIndex(temps_phones, j);  //这个就是电话号码
				int platform = (arc4random()%99999)%3;
				NSMutableDictionary * item = [[NSMutableDictionary alloc] initWithObjectsAndKeys:name,@"name",phoneNO,@"phone",[NSNumber numberWithInt:platform],@"platform",nil];
				[temp_array addObject:item];
				[item release];
				if (phoneNO) {
					CFRelease(phoneNO);
				}
			}
			if (temps_phones) {
				CFRelease(temps_phones);
			}
			if (name) {
				CFRelease(name);
			}
			
			CFRelease(person);
		}
	}
	if (personarray) {
		CFRelease(personarray);
	}
	NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]; 
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sorter count:1]; 
	NSArray *sortArray = [temp_array sortedArrayUsingDescriptors:sortDescriptors];
	[temp_array release];
	self.contactsArray = (NSMutableArray *)sortArray;
	
	[sorter release];
	[sortDescriptors release];
}

-(void)addLoadingView
{
	UIView *loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
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
	[label setText:@"wait ..."];
	[label setTextColor:[UIColor whiteColor]];
	[label setFont:[UIFont boldSystemFontOfSize:15.0f]];
	label.textAlignment = UITextAlignmentCenter;
	[loadingView addSubview:label];
	[label release];
	
	[self.view addSubview:loadingView];
	[loadingView release];
	
}
-(void)removeLoadingView
{
	UIView *LoadingView = [self.view viewWithTag:LoadingViewTag];
	if (LoadingView != nil) {
	    [LoadingView removeFromSuperview];
    }
}
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Contacts";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self addLoadingView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReferralMessage) name:@"HookNewReferralComplete" object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self getAddressPhones];
	[entriesView reloadData];
	[self removeLoadingView];
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
@end
