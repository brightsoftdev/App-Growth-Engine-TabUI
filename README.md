# App Growth Engine UI Tab for iOS

This project provides a ready-to-use user interface component for iPhone developers to easily incorporate AGE functionalities to their apps. The library adds a non-intrusive "tab" to your application's main window. The user can swipe open and close the tab to see suggestions to invite friends, and invite their friends right from within the application. The tab rotates with your application to support both portrait and landscape modes.

<center>
<img src="https://github.com/hookmobile/App-Growth-Engine-TabUI/raw/master/screen1.png" width="160"/>&nbsp;
<img src="https://github.com/hookmobile/App-Growth-Engine-TabUI/raw/master/screen2.png" width="240"/>&nbsp;
<img src="https://github.com/hookmobile/App-Growth-Engine-TabUI/raw/master/screen3.png" width="160"/>&nbsp;
<img src="https://github.com/hookmobile/App-Growth-Engine-TabUI/raw/master/screen4.png" width="160"/>
</center>

The library only takes minutes to setup, and two lines of code to integrate into your project. Try it today!

# Step 1: Register an account at Hook Mobile

To use the SDK, you first need to register an account and create an application. You will need your application key to setup the library.

<h3><center><a href="http://hookmobile.com/signup.html">Register</a></center></h3>

# Step 2: Install the library

To install the library, copy all files under the following two folders to your XCode project.

* TabUIExample/SDKClasses 
* TabUIExample/TabUI

In addition, the following two folders contain required 3rd party libraries. You should copy those files over if you do not already use those libraries.

* TabUIExample/SBJson (If you use the Facebook iOS SDK, you would already have SBJson)
* TabUIExample/SVProgressHUD

Finally, you need to add the following two iOS SDK frameworks to your project as dependencies:

* AddressBook.framework
* MessageUI.framework
* CoreGraphics.framework
* QuartzCore.framework
* OpenGLES.framework
* libz.dylib

# Step 3: Initialize the library

To add the tab in your application, add the following two lines of code into your app delegate.

<pre>
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // ... ...
    [[HookMainWindow sharedHookMainWindow] initWithWindow:self.window appKey:@"your-app-key" multiplayer:NO nativeInvite:YES];
    [[HookMainWindow sharedHookMainWindow] initDiscover];
    // ... ...    
}
</pre>

The <code>your-app-key</code> is the application key you created when you registered for an application on Hook Mobile's web site. The two parameters for the <code>HookMainWindow</code> instance are as follows.

* <code>nativeInvite</code>: This parameter indicates whether the application should pop up a native SMS composer when the user invites friends. Using the native SMS composer allows the invitation message to be sent from the user's own phone number. If the value is set to <code>NO</code>, the invitation SMS will be sent from Hook Mobile's server side phone number. The invitation will ALWAYS be sent from the Hook Mobile server if the user is on a non-SMS device, such as an iPod Touch.

* <code>multiplayer</code>: This parameter indicates whether your application could invite the user's friends to play together in a multi-player mode. When this parameter is set to <code>YES</code>, you will need to implement the <code>play</code> method in the <code>InstallsController</code> class. It provides you with a list of friends that user has selected and already have the app installed on their devices. The logic to setup the multi-player session for your game should be placed in the <code>play</code> method.


# Customization options

To customize the invitation message sent to friends, you can use the message template in <code>Constants.h</code>. The <code>inviteMsgTemplateNoName</code> is the invitation message to be sent from the user's own phone. It contains no user name since the recipient is supposed to have the sender in his or her address book. The <code>%link%</code> is replaced by the AGE server to uniquely track the invitation. The <code>inviteMsgTemplate</code> is the invitation message to be sent from Hook Mobile's server-side SMS number. The <code>%@</code> is replaced by the sender's name, and the <code>%%link%%</code> is replaced by an link to the app.

<pre>
#define inviteMsgTemplate @"From %@: I thought you might be interested in app 'AGE SDK', check it out %%link%% "
#define inviteMsgTemplateNoName @"I thought you might be interested in app 'AGE SDK', check it out %link% "
</pre>

Furthermore, from the <code>Constants.h</code> file, you can customize the text labels that appear on the tab user interface as well.

<pre>
#define inviteTabLabel @"Invite"
#define friendsTabLabel @"Friends"
#define playWithFriendsTabLabel @"Play with Friends"
</pre>


