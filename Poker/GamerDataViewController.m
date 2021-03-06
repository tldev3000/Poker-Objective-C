//
//  GamerDataViewController.m
//  Poker
//
//  Created by Admin on 22.04.15.
//  Copyright (c) 2015 by.bsuir.eLearning. All rights reserved.
//

#import "GamerDataViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "PlayGameViewController.h"
#import "JSONParser.h"
#import "UDPConnection.h"

#define GET_INVITE_TO_THE_GAME 0
#define GET_ACCEPT 1



@interface GamerDataViewController () 

-(void)checkDefaultParameters;
@property(nonatomic,strong)UIImage *buffImage;
@property (weak, nonatomic) IBOutlet UILabel *annotationAboutAccelerometerLabel;
@property (weak, nonatomic) IBOutlet UIButton *imageOfPlayerButton;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityAnswerFromServerView;

@end

@implementation GamerDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self checkDefaultParameters];
    [self setViewParameters];
    _buffImage = nil;
    [_enableAcceslerometerSwitcher setOn:NO animated:YES];
    [self setUDPConnection];
    

#if (TARGET_IPHONE_SIMULATOR)
    [_enableAcceslerometerSwitcher setEnabled:NO];
#endif
}

#pragma mark set UDP Connection

- (void)setUDPConnection {
    UDPConnection *udp = [UDPConnection sharedInstance];
    [udp bindSocket];
}

- (uint16_t)udpPBindedPort {
    UDPConnection *udp = [UDPConnection sharedInstance];
    return [udp getLocalUDPport];
}

#pragma mark - Set up view parameters

#define DEFAULT_CORNER_RADIUS 50

- (void)setCornerRadius:(UIView *)view andRadius:(int)radius
{
    [view.layer setMasksToBounds:YES];
    [view.layer setCornerRadius:radius];
}

-(void)setViewParameters {
    [self setCornerRadius:_sendEMessageButton andRadius:DEFAULT_CORNER_RADIUS / 10];
    [self setCornerRadius:_playButton andRadius:DEFAULT_CORNER_RADIUS];
    [self setCornerRadius:_imageOfPlayerButton andRadius:DEFAULT_CORNER_RADIUS / 10];
}

#pragma mark - IBAction methods


- (IBAction)sendMessageClick:(id)sender {
#if (TARGET_IPHONE_SIMULATOR)
    [[self createAlertViewAboutSuccesefullSendingMail] show];
    return;
#else
    [self createEmail];
#endif
}

- (IBAction)requestToInvitationInTheGame:(id)sender {
    TCPConnection *connection = [TCPConnection sharedInstance];
    connection.delegateForGamerVC = self;

    NSDictionary *requestDictiionary = [self createRequestAboutInvitationInGame];
    [connection sendDataWithTag:[JSONParser convertNSDictionaryToJSONdata:requestDictiionary] andTag:GET_INVITE_TO_THE_GAME];
    
    [_activityAnswerFromServerView startAnimating];
    
    
}

- (IBAction)switchIsUseAccelerometer { [self.enableAcceslerometerSwitcher setOn:![self.enableAcceslerometerSwitcher isOn] animated:YES];
    
}

- (IBAction)pickImageForGamer {
#if (TARGET_IPHONE_SIMULATOR)
    return;
#else
    
    if([self isPhotoLibraryAvaible]) {
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
        
        if([self canUserPickPhotosFromThotoLibrary]) {
            [mediaTypes addObject:(__bridge NSString*)kUTTypeImage];
        }
        controller.mediaTypes = mediaTypes;
        controller.delegate = self;
        //[self.navigationController presentModalViewController:controller animated:YES];
        [self.navigationController presentViewController:controller animated:YES completion:nil];
    }
#endif
}

#pragma mark - Methods for sending emails'

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    NSString *message = nil;
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            message = @"Result: canceled";
            break;
        case MFMailComposeResultSaved:
            message = @"Result: saved";
            break;
        case MFMailComposeResultSent:
            message = @"Result: sent";
            break;
        case MFMailComposeResultFailed:
            message = @"Result: failed";
            break;
        default:
            message = @"Result: not sent";
            break;
    }
    
    NSLog(@"%@", message);
    
   // [self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)createEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        //Тема письма
        [picker setSubject:@"Poker messager"];
        
        //Получатели
        NSArray *toRecipients = [NSArray arrayWithObject:@"AAA777SSS@yandex.ru"];
        NSArray *ccRecipients = [NSArray arrayWithObject:
                                 @"AAA777SSS@yandex.ru"];
        NSArray *bccRecipients = [NSArray arrayWithObject:@"AAA777SSS@yandex.ru"];
        
        [picker setToRecipients:toRecipients];
        [picker setCcRecipients:ccRecipients];
        [picker setBccRecipients:bccRecipients];
        
        NSString *emailBody = @"Hello from best poker in the World !";
        [picker setMessageBody:emailBody isHTML:NO];
        
       // [self presentModalViewController:picker animated:YES];
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        NSString *ccRecipients = @"schurik77799@gmail.com,AAA777SSS@yandex.ru";
        NSString *subject = @"Hello from best poker in the World !";
        NSString *recipients = [NSString stringWithFormat:
                                @"mailto:schurik77799@gmail.com?cc=%@&subject=%@",
                                ccRecipients, subject];
        NSString *body = @"&body=This is the simple message from best popker in the World !";
        
        NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
}

- (UIAlertView *)createAlertViewAboutSuccesefullSendingMail {
    return ([[UIAlertView alloc] initWithTitle:@"Success !"
                                       message:@"Благодарственное письмо отправлено !"
                                      delegate:self
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil]);
    
}


#pragma mark - Methods for set Attributed text


#define DEFAULT_TEXT_LENGTH_GAMERS_ICON_VIEW 8
#define DEFAULT_TEXT_SIZE_GAMER_ICON_VIEW 30

- (int)sizeForAttributedTextGamerIconView:(NSNumber *)money {
    NSString *gamerMoneyString = [NSString stringWithFormat:@"%@", money];
    
    int length = (int)[gamerMoneyString length];
    int needSize = (DEFAULT_TEXT_SIZE_GAMER_ICON_VIEW - 2*(length - DEFAULT_TEXT_LENGTH_GAMERS_ICON_VIEW));
    
    return needSize > DEFAULT_TEXT_SIZE_GAMER_ICON_VIEW ? DEFAULT_TEXT_SIZE_GAMER_ICON_VIEW : needSize;
}

- (NSAttributedString *)attributedStringForGamerMoney {
    UIColor *darkGreen = [UIColor colorWithRed:0.0 green:107.0f / 255.0f blue:41.0f / 255.0f alpha:1.0];
    int needSize = [self sizeForAttributedTextGamerIconView:[self getPlayersMoney]];
    
    NSAttributedString *attribString = [[NSAttributedString alloc] initWithString:[self prepareGamerMoneyBeforeRendering] attributes:@{
         NSFontAttributeName : [UIFont systemFontOfSize: needSize],
         NSForegroundColorAttributeName : [UIColor greenColor],
         NSStrokeWidthAttributeName : @-5,
         NSStrokeColorAttributeName : darkGreen,
         NSUnderlineStyleAttributeName : @(NSUnderlineStyleNone)                                                                                                          }];
    return attribString;
}
- (NSAttributedString *)attributedStringForGamerLevel {
    UIColor *darkBlue = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
    NSString *gamerLevelString = [NSString stringWithFormat:@"Level: %@", [self getPlayersLevel]];
    NSAttributedString *attribString = [[NSAttributedString alloc] initWithString:gamerLevelString attributes:@{
            NSFontAttributeName : [UIFont systemFontOfSize:30.0],
            NSForegroundColorAttributeName : [UIColor blueColor],
            NSStrokeWidthAttributeName : @-5,
            NSStrokeColorAttributeName : darkBlue,
            NSUnderlineStyleAttributeName : @(NSUnderlineStyleNone)                                                                                                          }];
    return attribString;
}


#define LENGTH_DISCHARGE_THOUSANDS 3

- (NSString *)prepareGamerMoneyBeforeRendering {
    NSString *resultString = @"Money: $";
    NSString *gamerMoney = [NSString stringWithFormat:@"%@", [self getPlayersMoney]];
    
    int countOfFirstNumbers = [gamerMoney length] % LENGTH_DISCHARGE_THOUSANDS;
    
    resultString = [resultString stringByAppendingString:[gamerMoney substringWithRange:NSMakeRange(0, countOfFirstNumbers)]];

    for(int i=countOfFirstNumbers; i < [gamerMoney length]; i+=LENGTH_DISCHARGE_THOUSANDS) {
        NSString *partOfString = [NSString stringWithFormat:@" %@", [gamerMoney substringWithRange:NSMakeRange(i, LENGTH_DISCHARGE_THOUSANDS)]];
        resultString = [resultString stringByAppendingString:partOfString];
    }
        return resultString;
}


#pragma mark - Methods for set and check default parameters'

-(void)checkDefaultParameters{
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *result = [userDefaults objectForKey:@"name"];
    if(![result length]) {
        [userDefaults setObject:@"Anonymos" forKey:@"name"];
        self.gamerName.text = @"Something wronNNNNG ! ";
        [userDefaults setObject:[NSNumber numberWithLong:18900000] forKey:@"money"];
        [userDefaults setInteger:0 forKey:@"level"];
        [userDefaults setObject:@"defaultImage.jpg" forKey:@"image"];
        [userDefaults synchronize];
    }
    
    [_gamerMoneyLabel setAttributedText:[self attributedStringForGamerMoney]];
    [_gamersLevel setAttributedText:[self attributedStringForGamerLevel]];
}

#pragma mark - Methods get&set defaultInfo

- (void)setNewGamerName       {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[self.gamerName text] forKey:@"name"];
    [userDefaults synchronize];
}

- (NSNumber *)getPlayersMoney {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:@"money"];
}
- (NSNumber *)getPlayersLevel {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:@"level"];
}
- (NSString *)getPlayersName  {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:@"name"];
}

#pragma mark - Additional methods for create and send JSON


- (UIAlertView *)createAlertViewAboutError {
    return ([[UIAlertView alloc] initWithTitle:@"Error :("
                                       message:@"Check connection to WiFi and repeat again"
                                      delegate:self
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil]);
}


- (NSDictionary *)createInformationAboutPlayer {
    NSDictionary *data = @{
                           @"name"  : [self getPlayersName],
                           @"money" : [self getPlayersMoney],
                           @"level" : [self getPlayersLevel],
                           @"udpPort" : [NSNumber numberWithUnsignedInt:[self udpPBindedPort]]
    };
    return data;
}
- (NSDictionary *)createRequestAboutInvitationInGame {
    NSDictionary *data = @{  @"request" : @"play"  };
    return data;
}

- (NSData *)downloadedData {
    TCPConnection *connect = [TCPConnection sharedInstance];
    return connect.downloadedData;
}

- (void)sendJSONDataAboutGamer
{
    TCPConnection *connection = [TCPConnection sharedInstance];
    
     NSDictionary *dictionary = [self createInformationAboutPlayer];
    [connection sendDataWithTag:[JSONParser convertNSDictionaryToJSONdata:dictionary] andTag:GET_ACCEPT];
}

#pragma mark - ConnectionToServerDelegateForGamerDataViewController

- (void)parseResponseFromServer {

    NSDictionary *dictionary = [JSONParser convertJSONdataToNSDictionary:[self downloadedData]];
    NSString *title = [JSONParser getNSStringWithObject:dictionary[@"title"]];
    
    if([title isEqualToString:@"inviteToTheGame"]) {
        BOOL isInGame = [JSONParser getBOOLValueWithObject:dictionary[@"inGame"]];
        BOOL isNeedToSendInformation = [JSONParser getBOOLValueWithObject:dictionary[@"Information"]];
        
        if(isInGame && isNeedToSendInformation) {
            [self setNewGamerName];
            [self sendJSONDataAboutGamer];
        }
    }
}


- (void)segueToGeneralViewController {
    [_activityAnswerFromServerView stopAnimating];
    [self performSegueWithIdentifier:@"segueToPlayGameVC" sender:self];
}

#pragma mark -  UIImagePickerController delegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if([mediaType isEqualToString:(__bridge NSString*)kUTTypeImage]) {
        UIImage *theImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        _buffImage = theImage;
        [self.imageOfPlayerButton setBackgroundImage:theImage forState:UIControlStateNormal];
        
        [self.imageOfPlayerButton reloadInputViews];
        //[_imageOfGamer setImage:theImage];;
        //[_imageOfGamer reloadInputViews];
    }
}
-(BOOL)isPhotoLibraryAvaible {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
}

-(BOOL)camerSupportMedia:(NSString*)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    
    if([paramMediaType length] == 0) {
        return  0;
    }
    NSArray *avaibleMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    
    [avaibleMediaTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *mediaType = (NSString*)obj;
        if([mediaType isEqualToString:paramMediaType]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

-(BOOL)canUserPickPhotosFromThotoLibrary {
    return [self camerSupportMedia:(__bridge NSString*)kUTTypeImage sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    PlayGameViewController *secVC = [segue destinationViewController];
    secVC.isUseAccelerometer = [_enableAcceslerometerSwitcher isOn];
    secVC.hashValueOfGamerName = [[self getPlayersName] hash];
}

-(void)returnOnPreviusView {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
