//
//  ViewController.m
//  Poker
//
//  Created by Admin on 20.04.15.
//  Copyright (c) 2015 by.bsuir.eLearning. All rights reserved.
//

#import "ViewController.h"
#import "GamerDataViewController.h"
#import "SoundManager.h"

@interface ViewController () 

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
#if !(TARGET_IPHONE_SIMULATOR)
    [[UIAccelerometer sharedAccelerometer]setDelegate:self];
    
    [SoundManager sharedManager].allowsBackgroundMusic = YES;
    [[SoundManager sharedManager] prepareToPlay];
    [[SoundManager sharedManager] playSound:@"JamesBond" looping:NO];
#endif
}

- (IBAction)connectClickButton:(id)sender {
 
    ConnectionToServer *connection = [ConnectionToServer sharedInstance];
    [connection setParameters:_ipAdressTextField.text andPort:_portTextField.text];
    connection.delegateForRootVC = self;
    [connection connectToServer];
}


#pragma mark Connected
-(void)connected {
        [self.audioPlayer stop];
        [self performSegueWithIdentifier:@"segueToGamerDataVC" sender:self];
}


-(void)returnOnPreviusView {
    [[self alertWithError] show];
}

- (UIAlertView *)alertWithError{
    return([[UIAlertView alloc] initWithTitle:@"Error :("
                                          message:@"Check connection to WiFi and repeat again"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:nil]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
