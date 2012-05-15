#import <UIKit/UIKit.h>
#import "Constants.h"

@interface RecommendsController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    
	IBOutlet UITableView *entriesView;
    NSArray *recommends;
    NSMutableArray *phones;
    
    BOOL sendNow;
}

@property (nonatomic,retain) UITableView *entriesView;
@property (nonatomic) BOOL sendNow;

- (IBAction) refer: (id) sender;
- (IBAction) refresh: (id) sender;

// -(void)initRecommends;

- (void) showReferralMessage;
- (void) sendReferral;

// -(void)addLoadingView;
// -(void)removeLoadingView;

@end
