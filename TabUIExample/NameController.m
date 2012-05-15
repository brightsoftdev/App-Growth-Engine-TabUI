//
//  NameController.m
//  TabUIExample
//
//  Created by Michael Yuan on 5/10/12.
//  Copyright (c) 2012 Ringful LLC. All rights reserved.
//

#import "NameController.h"
#import "Discoverer.h"
#import "HookMainWindow.h"

@implementation NameController

@synthesize phones;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction) done: (id) sender {
    NSString *name = nameField.text;
    if (name == nil || [@"" isEqualToString:name]) {
        name = @"a friend";
    }
    [HookMainWindow saveName:name];
    
    [[Discoverer agent] newReferral:phones withMessage:[NSString stringWithFormat:inviteMsgTemplate, name] useVirtualNumber:YES];
    
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    nameField.text = [HookMainWindow findName];
    [nameField becomeFirstResponder];
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
