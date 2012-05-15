#import <Foundation/Foundation.h>


@interface ReferralRecord : NSObject {
    
    int totalClickThrough;
    int totalInvitee;
    NSDate *invitationDate;
    
}

@property (nonatomic) int totalClickThrough;
@property (nonatomic) int totalInvitee;
@property (nonatomic, retain) NSDate *invitationDate;

- (id) init;

@end
