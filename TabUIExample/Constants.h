#define BARBUTTON(TITLE, STYLE, SELECTOR) [[[UIBarButtonItem alloc] initWithTitle:TITLE style:STYLE target:self action:SELECTOR] autorelease]
#define SYSBARBUTTON(STYLE, SELECTOR) [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:STYLE target:self action:SELECTOR] autorelease]
#define IMGBARBUTTON(IMAGE, STYLE, SELECTOR) [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:IMAGE] style:STYLE target:self action:SELECTOR] autorelease]

#define inviteMsgTemplate @"From %@: I thought you might be interested in app 'AGE SDK', check it out %%link%% "
#define inviteMsgTemplateNoName @"I thought you might be interested in app 'AGE SDK', check it out %link% "
#define inviteTabLabel @"Invite"
#define friendsTabLabel @"Friends"
#define playWithFriendsTabLabel @"Play with Friends"
