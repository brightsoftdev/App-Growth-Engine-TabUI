#import <UIKit/UIKit.h>
#import "Constants.h"

@interface ContactsController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    
    IBOutlet UITableView *entriesView;
    
    NSMutableArray *contactsArray;
	BOOL searchIsActive;
	
    BOOL sendNow;
    NSMutableArray *phones;
}

@property (nonatomic,retain) NSMutableArray *searchListContent;
@property (nonatomic,retain) NSMutableArray *contactsArray;
@property (nonatomic) BOOL sendNow;

-(void)getAddressPhones;

@end
