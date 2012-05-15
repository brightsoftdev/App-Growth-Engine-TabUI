#import "Discoverer.h"
#import "JSON.h"
#import "Lead.h"
#import "ReferralRecord.h"
#import <AddressBook/AddressBook.h>
#import "UIDevice-Hardware.h"

static Discoverer *_agent;

@implementation Discoverer

@synthesize server, SMSDest, appKey, /* runQueryAfterOrder, */ queryStatus, errorMessage, leads, installs, referrals;
@synthesize fbTemplate, emailTemplate, smsTemplate, twitterTemplate;
@synthesize referralMessage;
@synthesize installCode;

- (id) init {
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
		installCode = [[standardUserDefaults objectForKey:@"installCode"] retain];
    }
    
    return self;
}

- (BOOL) isRegistered{
    if (installCode == nil || [installCode length] == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL) verifyDevice:(UIViewController *)vc forceSms:(BOOL) force userName:(NSString *) userName {
    if (verifyDeviceConnection != nil) {
        return NO;
    }
    if (vc != nil) {
        viewController = [vc retain];
        forceVerificationSms = force;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/newverify", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&verifyMessageTemplate=%@", [@"Please send this SMS to confirm your device %installCode%" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    if (userName != nil) {
        [postBody appendData:[[NSString stringWithFormat:@"&name=%@", [userName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		verifyDeviceData = [[NSMutableData data] retain];
        verifyDeviceConnection = [connection retain];
	}
    
    return YES;
}

- (BOOL) queryVerifiedStatus {
    if (verificationConnection != nil || installCode == nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryverify", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		verificationData = [[NSMutableData data] retain];
        verificationConnection = [connection retain];
	}
    return YES;
}


- (BOOL) discover {
    if (discoverConnection != nil) {
        return NO;
    }
    
    NSLog(@"installCode is %@", installCode);
    
    NSString *ab = [self getAddressbook];
    if (![self checkNewAddresses:ab]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HookDiscoverNoChange" object:nil];
        return YES;
    } 
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/newleads", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    if (installCode != nil ) {
        [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    NSString *encodedJsonStr = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)ab, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
	[postBody appendData:[[NSString stringWithFormat:@"&addressBook=%@", encodedJsonStr] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		discoverData = [[NSMutableData data] retain];
        discoverConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}

- (BOOL) discoverWithoutVzw {
    if (discoverConnection != nil) {
        return NO;
    }
    
    NSLog(@"installCode is %@", installCode);
    
    NSString *ab = [self getAddressbook];
    if (![self checkNewAddresses:ab]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HookDiscoverNoChange" object:nil];
        return YES;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/newleads", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    if (installCode != nil ) {
        [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    NSString *encodedJsonStr = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)ab, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
	[postBody appendData:[[NSString stringWithFormat:@"&addressBook=%@", encodedJsonStr] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&queryDeviceCarrierExclusions=38"] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		discoverData = [[NSMutableData data] retain];
        discoverConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}

// contacts must be an array of dictionaries
// Each dictionary has
//    phone
//    firstName
//    lastName
- (BOOL) discoverSelected:(NSMutableArray *)contacts {
    if (discoverConnection != nil) {
        return NO;
    }
    
    NSLog(@"installCode is %@", installCode);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/selectupdate", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    if (installCode != nil ) {
        [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    SBJSON *jsonWriter = [[SBJSON new] autorelease];
    jsonWriter.humanReadable = YES;
    NSString *jsonStr = [jsonWriter stringWithObject:contacts];
    NSLog(@"JSON Object --> %@", jsonStr);
    NSString *encodedJsonStr = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)jsonStr, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    
	[postBody appendData:[[NSString stringWithFormat:@"&addressBook=%@", encodedJsonStr] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceModel=%@", [[UIDevice currentDevice] platformString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&deviceOs=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		discoverData = [[NSMutableData data] retain];
        discoverConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}

- (BOOL) queryOrder {
    if (queryOrderConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryleads", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&order=%d", orderid] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		queryOrderData = [[NSMutableData data] retain];
        queryOrderConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}

- (BOOL) downloadShareTemplates {
    if (shareTemplateConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/template", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		shareTemplateData = [[NSMutableData data] retain];
        shareTemplateConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}

- (BOOL) newReferral:(NSArray *)phones withMessage:(NSString *)message useVirtualNumber:(BOOL) sendNow {
    
    if (newReferralConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/newreferral", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    for (NSString *phone in phones) {
        NSString *encodedPhone = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)phone, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
        [postBody appendData:[[NSString stringWithFormat:@"&phone=%@", encodedPhone] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [postBody appendData:[[NSString stringWithFormat:@"&referralTemplate=%@", [message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"&useShortUrl=true" dataUsingEncoding:NSUTF8StringEncoding]];
    if (sendNow) {
        [postBody appendData:[@"&sendNow=true" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		newReferralData = [[NSMutableData data] retain];
        newReferralConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}

- (BOOL) updateReferral:(BOOL) sent {
    if (updateReferralConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/updatereferral", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&referralId=%d", referralId] dataUsingEncoding:NSUTF8StringEncoding]];
    if (sent) {
        [postBody appendData:[@"&action=sent" dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        [postBody appendData:[@"&action=cancel" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		updateReferralData = [[NSMutableData data] retain];
        updateReferralConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}

- (BOOL) queryInstalls:(NSString *)direction {
    if (queryInstallsConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryinstalls", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&reference=%@", [direction stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		queryInstallsData = [[NSMutableData data] retain];
        queryInstallsConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}

- (BOOL) queryReferral {
    if (queryReferralConnection != nil) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/queryreferral", server]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"appKey=%@", [appKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"&installCode=%@", [installCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
		queryReferralData = [[NSMutableData data] retain];
        queryReferralConnection = [connection retain];
	}
    // [connection release];
    
    return YES;
}


- (NSString *) getAddressbook {
    ABAddressBookRef ab = ABAddressBookCreate();
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(ab);
    CFIndex nPeople = ABAddressBookGetPersonCount(ab);
    
    NSMutableArray *phones = [[NSMutableArray alloc] init];
    for (int i = 0; i < nPeople; i++) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
        CFStringRef firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        CFStringRef lastName = ABRecordCopyValue(ref, kABPersonLastNameProperty);
        
        NSString *firstNameStr = (NSString *) firstName;
        if (firstNameStr == nil) {
            firstNameStr = @"";
        }
        if (![firstNameStr canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            firstNameStr = @"NONASCII";
        }
        NSString *lastNameStr = (NSString *) lastName;
        if (lastNameStr == nil) {
            lastNameStr = @"";
        }
        if (![lastNameStr canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            lastNameStr = @"NONASCII";
        }
        
        ABMultiValueRef ps = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        CFIndex count = ABMultiValueGetCount (ps);
        for (int i = 0; i < count; i++) {
            CFStringRef phone = ABMultiValueCopyValueAtIndex (ps, i);
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:16];
            [dic setObject:((NSString *) phone) forKey:@"phone"];
            [dic setObject:((NSString *) firstNameStr) forKey:@"firstName"];
            [dic setObject:((NSString *) lastNameStr) forKey:@"lastName"];
            [phones addObject:dic];
            [dic release];
            
            if (phone) {
                CFRelease(phone);
            }
        }
        
        if (firstName) {
            CFRelease(firstName);
        }
        if (lastName) {
            CFRelease(lastName);
        }
    }
	if (allPeople) {
        CFRelease(allPeople);
    }
    
    // create json for phone and name based on phones
    SBJSON *jsonWriter = [[SBJSON new] autorelease];
    jsonWriter.humanReadable = YES;
    NSString *jsonStr = [jsonWriter stringWithObject:phones];
    NSLog(@"JSON Object --> %@", jsonStr);
    
    return jsonStr;
}

- (void) createVerificationSms {
    if (viewController != nil) {
        if ([MFMessageComposeViewController canSendText]) {
            NSLog(@"Show SMS confirmation");
            MFMessageComposeViewController *controller = [[[MFMessageComposeViewController alloc] init] autorelease];
            controller.body = verifyMessage;
            controller.recipients = [NSArray arrayWithObjects:SMSDest, nil];
            controller.messageComposeDelegate = self;
            [viewController presentModalViewController:controller animated:YES];
        } else {
            NSLog(@"Not a SMS device. Fail silently.");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookNotSMSDevice" object:nil];
        }
    }
}

- (NSString *) lookupNameFromPhone:(NSString *)p {
    NSString *name;
    
    ABAddressBookRef ab = ABAddressBookCreate();
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(ab);
    CFIndex nPeople = ABAddressBookGetPersonCount(ab);
    
    for (int i = 0; i < nPeople; i++) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
        CFStringRef firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        CFStringRef lastName = ABRecordCopyValue(ref, kABPersonLastNameProperty);
        CFStringRef suffix = ABRecordCopyValue(ref, kABPersonSuffixProperty);
        
        NSString *firstNameStr = (NSString *) firstName;
        if (firstNameStr == nil) {
            firstNameStr = @"";
        }
        NSString *lastNameStr = (NSString *) lastName;
        if (lastNameStr == nil) {
            lastNameStr = @"";
        }
        NSString *suffixStr = (NSString *) suffix;
        if (suffixStr == nil) {
            suffixStr = @"";
        }
        
        ABMultiValueRef ps = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        CFIndex count = ABMultiValueGetCount (ps);
        for (int i = 0; i < count; i++) {
            CFStringRef phone = ABMultiValueCopyValueAtIndex (ps, i);
            
            if ([p isEqualToString:[self formatPhone:((NSString *) phone)]]) {
                name = [NSString stringWithFormat:@"%@ %@ %@", firstNameStr, lastNameStr, suffixStr];
                break;
            }
            
            if (phone) {
                CFRelease(phone);
            }
        }
        
        if (firstName) {
            CFRelease(firstName);
        }
        if (lastName) {
            CFRelease(lastName);
        }
    }
	if (allPeople) {
        CFRelease(allPeople);
    }
    
    return name;
}

- (NSString *) formatPhone:(NSString *)p {
    p = [p stringByReplacingOccurrencesOfString:@"(" withString:@""];
    p = [p stringByReplacingOccurrencesOfString:@")" withString:@""];
    p = [p stringByReplacingOccurrencesOfString:@" " withString:@""];
    p = [p stringByReplacingOccurrencesOfString:@"-" withString:@""];
    p = [p stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    int length = [p length];
    if(length == 10) {
        p = [NSString stringWithFormat:@"+1%@", p];
    } else if (length == 11) {
        p = [NSString stringWithFormat:@"+%@", p];
    }
    
    return p;
}

- (BOOL) checkNewAddresses:(NSString *)ab {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (standardUserDefaults) {
        NSString *saved = [standardUserDefaults objectForKey:@"HOOKADDRESSBOOK"];
        if (saved == nil || ![saved isEqualToString:ab]) {
            [standardUserDefaults setObject:ab forKey:@"HOOKADDRESSBOOK"];
            [standardUserDefaults synchronize];
            return YES;
        } else {
            return NO;
        }
    }
    return YES;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    [viewController dismissModalViewControllerAnimated:YES];
    
    if (result == MessageComposeResultCancelled) {
        // the SMS stays. No cancel
        UIAlertView* alert = [[UIAlertView alloc] init];
        alert.title = @"Confirmation";
        alert.message = @"You can only proceed after you send the confirmation SMS";
        [alert addButtonWithTitle:@"Okay"];
        // alert.cancelButtonIndex = 0;
        alert.delegate = self;
        [alert show];
        [alert release];
        
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HookVerificationSMSSent" object:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self createVerificationSms];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog (@"Received response");
    if (connection == verifyDeviceConnection) {
        [verifyDeviceData setLength:0];
    }
    if (connection == verificationConnection) {
        [verificationData setLength:0];
    }
    if (connection == discoverConnection) {
        [discoverData setLength:0];
    }
    if (connection == queryOrderConnection) {
        [queryOrderData setLength:0];
    }
    if (connection == shareTemplateConnection) {
        [shareTemplateData setLength:0];
    }
    if (connection == newReferralConnection) {
        [newReferralData setLength:0];
    }
    if (connection == updateReferralConnection) {
        [updateReferralData setLength:0];
    }
    if (connection == queryInstallsConnection) {
        [queryInstallsData setLength:0];
    }
    if (connection == queryReferralConnection) {
        [queryReferralData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (connection == verifyDeviceConnection) {
        [verifyDeviceData appendData:data];
    }
    if (connection == verificationConnection) {
        [verificationData appendData:data];
    }
    if (connection == discoverConnection) {
        [discoverData appendData:data];
    }
    if (connection == queryOrderConnection) {
        [queryOrderData appendData:data];
    }
    if (connection == shareTemplateConnection) {
        [shareTemplateData appendData:data];
    }
    if (connection == newReferralConnection) {
        [newReferralData appendData:data];
    }
    if (connection == updateReferralConnection) {
        [updateReferralData appendData:data];
    }
    if (connection == queryInstallsConnection) {
        [queryInstallsData appendData:data];
    }
    if (connection == queryReferralConnection) {
        [queryReferralData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog (@"Received error with code %d", error.code);
    if (connection == verifyDeviceConnection) {
        [verifyDeviceData release];
        [verifyDeviceConnection release];
        verifyDeviceConnection = nil;
    }
    if (connection == verificationConnection) {
        [verificationData release];
        [verificationConnection release];
        verificationConnection = nil;
    }
    if (connection == discoverConnection) {
        [discoverData release];
        [discoverConnection release];
        discoverConnection = nil;
    }
    if (connection == queryOrderConnection) {
        [queryOrderData release];
        [queryOrderConnection release];
        queryOrderConnection = nil;
    }
    if (connection == shareTemplateConnection) {
        [shareTemplateData release];
        [shareTemplateConnection release];
        shareTemplateConnection = nil;
    }
    if (connection == newReferralConnection) {
        [newReferralData release];
        [newReferralConnection release];
        newReferralConnection = nil;
    }
    if (connection == updateReferralConnection) {
        [updateReferralData release];
        [updateReferralConnection release];
        updateReferralConnection = nil;
    }
    if (connection == queryInstallsConnection) {
        [queryInstallsData release];
        [queryInstallsConnection release];
        queryInstallsConnection = nil;
    }
    if (connection == queryReferralConnection) {
        [queryReferralData release];
        [queryReferralConnection release];
        queryReferralConnection = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HookNetworkError" object:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog (@"Finished loading data");
    
    if (connection == verifyDeviceConnection) {
        NSString *dataStr = [[[NSString alloc] initWithData:verifyDeviceData encoding:NSUTF8StringEncoding] autorelease];
        NSLog (@"verifyDevice data is %@", dataStr);
        [verifyDeviceData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            if (standardUserDefaults) {
                installCode = [[resp objectForKey:@"installCode"] retain];
                [standardUserDefaults setObject:installCode forKey:@"installCode"];
                [standardUserDefaults synchronize];
            }
            verifyMessage = [[resp objectForKey:@"verifyMessage"] retain];
        }
        
        [self createVerificationSms];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HookVerifyDeviceComplete" object:[resp objectForKey:@"status"]];
        
        [verifyDeviceConnection release];
        verifyDeviceConnection = nil;
    }
    
    if (connection == verificationConnection) {
        NSString *dataStr = [[[NSString alloc] initWithData:verificationData encoding:NSUTF8StringEncoding] autorelease];
        NSLog (@"verification data is %@", dataStr);
        [verificationData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSString *verified = [resp objectForKey:@"verified"];
            if ([verified isEqualToString:@"true"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"HookDeviceVerified" object:nil];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"HookDeviceNotVerified" object:nil];
            }
        }
        
        [verificationConnection release];
        verificationConnection = nil;
    }
    
    if (connection == discoverConnection) {
        NSString *dataStr = [[[NSString alloc] initWithData:discoverData encoding:NSUTF8StringEncoding] autorelease];
        NSLog (@"discover data is %@", dataStr);
        [discoverData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            if (standardUserDefaults) {
                installCode = [[resp objectForKey:@"installCode"] retain];
                [standardUserDefaults setObject:installCode forKey:@"installCode"];
                [standardUserDefaults synchronize];
            }
            orderid = [[resp objectForKey:@"order"] intValue];
            
            NSLog(@"installCode is %@", installCode);
            NSLog(@"orderid is %d", orderid);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookDiscoverComplete" object:nil];
            /*
            if (runQueryAfterOrder) {
                [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(queryOrder) userInfo:nil repeats:NO];
                // [self queryOrder];
            }
            */
        }
        
        [discoverConnection release];
        discoverConnection = nil;
    }
        
    if (connection == queryOrderConnection) {
        NSString *dataStr = [[[NSString alloc] initWithData:queryOrderData encoding:NSUTF8StringEncoding] autorelease];
        NSLog (@"query order data is %@", dataStr);
        [queryOrderData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        int status = [[resp objectForKey:@"status"] intValue];
        if (status == 1000) {
            queryStatus = YES;
        } else {
            queryStatus = NO;
        }
        if (status == 1000 || status == 1500) {
            leads = [[NSMutableArray arrayWithCapacity:16] retain];
            NSArray *ls = [resp objectForKey:@"leads"];
            if (ls != nil && [ls count] > 0) {
                for (NSDictionary *d in ls) {
                    Lead *lead = [[Lead alloc] init];
                    lead.phone = [d objectForKey:@"phone"];
                    lead.osType = [d objectForKey:@"osType"];
                    lead.invitationCount = [[resp objectForKey:@"invitationCount"] intValue];
                    lead.name = [[Discoverer agent] lookupNameFromPhone:lead.phone];
                    
                    NSString *dateStr = [d objectForKey:@"lastInvitationSent"];
                    if (dateStr == nil || [@"" isEqualToString:dateStr]) {
                    } else {
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss.S"];
                        lead.lastInvitationSent = [dateFormat dateFromString:dateStr];
                        [dateFormat release];
                    }
                    
                    [leads addObject:lead];
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookQueryOrderComplete" object:nil];
        } else {
            errorMessage = [[resp objectForKey:@"desc"] retain];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookQueryOrderFailed" object:nil];
        }
        /*
        else if ([[resp objectForKey:@"status"] intValue] == 1234) {
            // pending. Let's run this again after some delay
            // [self performSelector:@selector(queryOrder) withObject:nil afterDelay:10.0];
            [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(queryOrder) userInfo:nil repeats:NO];
        }
        */
        
        [queryOrderConnection release];
        queryOrderConnection = nil;
    }
    
    if (connection == shareTemplateConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:shareTemplateData encoding:NSUTF8StringEncoding];
        NSLog (@"share template data is %@", dataStr);
        [shareTemplateData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        if ([@"ok" isEqualToString:[resp objectForKey:@"status"]]) {
            fbTemplate = [[resp objectForKey:@"fb"] retain];
            twitterTemplate = [[resp objectForKey:@"twitter"] retain];
            emailTemplate = [[resp objectForKey:@"email"] retain];
            smsTemplate = [[resp objectForKey:@"sms"] retain];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HookDownloadShareTemplatesComplete" object:nil];
        
        [shareTemplateConnection release];
        shareTemplateConnection = nil;
    }
    
    if (connection == newReferralConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:newReferralData encoding:NSUTF8StringEncoding];
        NSLog (@"new referral data is %@", dataStr);
        [newReferralData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        if ([[resp objectForKey:@"status"] intValue] == 1000) {
            referralId = [[resp objectForKey:@"referralId"] intValue];
            referralMessage = [[resp objectForKey:@"referralMessage"] retain];
            invitationUrl = [[resp objectForKey:@"url"] retain];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HookNewReferralComplete" object:nil];
        
        [newReferralConnection release];
        newReferralConnection = nil;
    }
    
    if (connection == updateReferralConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:updateReferralData encoding:NSUTF8StringEncoding];
        NSLog (@"update referral data is %@", dataStr);
        [updateReferralData release];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HookUpdateReferralComplete" object:nil];
        
        [updateReferralConnection release];
        updateReferralConnection = nil;
    }
    
    if (connection == queryInstallsConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:queryInstallsData encoding:NSUTF8StringEncoding];
        NSLog (@"query installs data is %@", dataStr);
        [queryInstallsData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        int status = [[resp objectForKey:@"status"] intValue];
        if (status == 1000) {
            installs = [[NSMutableArray arrayWithCapacity:16] retain];
            NSArray *ls = [resp objectForKey:@"leads"];
            if (ls != nil && [ls count] > 0) {
                for (NSString *p in ls) {
                    Lead *lead = [[Lead alloc] init];
                    lead.phone = p;
                    lead.name = [[Discoverer agent] lookupNameFromPhone:lead.phone];
                    [installs addObject:lead];
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookQueryInstallsComplete" object:nil];
        } else {
            errorMessage = [[resp objectForKey:@"desc"] retain];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookQueryInstallsFailed" object:nil];
        }
        
        [queryInstallsConnection release];
        queryInstallsConnection = nil;
    }
    
    if (connection == queryReferralConnection) {
        NSString *dataStr = [[NSString alloc] initWithData:queryReferralData encoding:NSUTF8StringEncoding];
        NSLog (@"query referral data is %@", dataStr);
        [queryReferralData release];
        
        SBJSON *jsonReader = [[SBJSON new] autorelease];
        NSDictionary *resp = [jsonReader objectWithString:dataStr];
        int status = [[resp objectForKey:@"status"] intValue];
        if (status == 1000) {
            referrals = [[NSMutableArray arrayWithCapacity:16] retain];
            NSArray *ls = [resp objectForKey:@"referrals"];
            if (ls != nil && [ls count] > 0) {
                for (NSDictionary *d in ls) {
                    ReferralRecord *rec = [[ReferralRecord alloc] init];
                    rec.totalClickThrough = [[d objectForKey:@"totalClickThrough"] intValue];
                    rec.totalInvitee = [[d objectForKey:@"totalInvitee"] intValue];
                    NSString *dateStr = [d objectForKey:@"date"];
                    if (dateStr == nil || [@"" isEqualToString:dateStr]) {
                    } else {
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss.S"];
                        rec.invitationDate = [dateFormat dateFromString:dateStr];
                        [dateFormat release];
                    }
                    [referrals addObject:rec];
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookQueryReferralComplete" object:nil];
        } else {
            errorMessage = [[resp objectForKey:@"desc"] retain];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HookQueryReferralFailed" object:nil];
        }
        
        [queryReferralConnection release];
        queryReferralConnection = nil;
    }
}



+ (void) activate:(NSString *)ak {
    if (_agent) {
        return;
    }
    
    _agent = [[Discoverer alloc] init];
    _agent.server = @"https://age.hookmobile.com";
    _agent.SMSDest = @"3025175040";
    _agent.appKey = ak;
    
    return;
}


+ (void) retire {
    [_agent release];
    _agent = nil;
}

+ (Discoverer *) agent {
    if (_agent == nil) {
        [NSException raise:@"InstanceNotExists"
                    format:@"Attempted to access instance before initializaion. Please call activate: first."];
    }
    return _agent;
}


@end