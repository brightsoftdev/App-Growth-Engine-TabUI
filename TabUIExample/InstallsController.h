#import <UIKit/UIKit.h>
#import "Constants.h"

@interface InstallsController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    
    IBOutlet UITableView *entriesView;
    NSMutableArray *installs;
    NSMutableArray *phones;
    
    BOOL viewOnly;
}

- (IBAction) play: (id) sender;
- (IBAction) refresh: (id) sender;

@property (nonatomic,retain) UITableView *entriesView;
@property (nonatomic) BOOL viewOnly;

// -(void)initInstalls;

// -(void)addLoadingView;
// -(void)removeLoadingView;

@end
