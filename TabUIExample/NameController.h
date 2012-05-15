#import <UIKit/UIKit.h>
#import "Constants.h"

@interface NameController : UIViewController {
    IBOutlet UITextField *nameField;
    NSArray *phones;
}

@property (nonatomic,retain) NSArray *phones;

- (IBAction) done: (id) sender;

@end
