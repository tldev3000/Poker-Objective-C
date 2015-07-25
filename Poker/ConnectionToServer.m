//
//  ConnectionToServer.m
//  Poker
//
//  Created by Admin on 03.05.15.
//  Copyright (c) 2015 by.bsuir.eLearning. All rights reserved.
//

#import "ConnectionToServer.h"


#define GET_INVITE_TO_THE_GAME 0
#define GET_ACCEPT 1

#define TIME_OUT 3
#define LONG_TIME_OUT 60

#define DID_WRITE_RESPONSE 101

#define MAX_DURATION_OF_PARTY 1080

@implementation ConnectionToServer


static const int ddLogLevel = LOG_LEVEL_INFO;

static ConnectionToServer *mySinglConnection = nil;

-(id)init{
    self = [super init];
    
    if(self) {
        _mainQueue = nil;
        _asyncSocket = nil;
        _isConnected = NO;
    }
    return self;
}

+ (id)sharedInstance {
    @synchronized(self) {
        if(mySinglConnection == nil) {
            mySinglConnection = [[ConnectionToServer alloc] init];
        }
    }
    return mySinglConnection;
}


//-------------------SENDING--------------------------------------------

-(void)sendDataWithTag:(NSData *)data andTag:(int)tag {
    [_asyncSocket writeData:data withTimeout:1 tag:tag];
}

//---------------------------------------------------------------------


//-------------------RECEIVING-----------------------------------------
-(void)readDataWithTag:(int)tag {
        NSLog(@"%@, tag : %d", THIS_METHOD, tag);
        NSMutableData *myData = [[NSMutableData alloc] init];
        [_asyncSocket readDataWithTimeout:LONG_TIME_OUT buffer:myData bufferOffset:0 tag:tag];
}


-(void)readDataWithTagLongTime:(int)tag andDurationWaiting:(int)duration {
        NSLog(@"%@, tag : %d", THIS_METHOD, tag);
        NSMutableData *myData = [[NSMutableData alloc] init];
        [_asyncSocket readDataWithTimeout:duration buffer:myData bufferOffset:0 tag:tag];
}
//----------------------------------------------------------------------


-(void)setParameters:(NSString*)ip andPort:(NSString*)myPort{
    _ipAdressTextField = ip;
    _portTextField = myPort;
}

-(void)connectToServer{
    
    _mainQueue = dispatch_get_main_queue();
    _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_mainQueue];
    
    uint16_t port = [_portTextField intValue];
    
    DDLogInfo(@"Connecting to \"%@\" on port %huu...", _ipAdressTextField, port);
    
    NSError *error = nil;
    if (![_asyncSocket connectToHost:_ipAdressTextField onPort:port error:&error])
    {
        DDLogError(@"Error connecting: %@", error);
    } else {
        DDLogError(@"Success connecting: %@", error);
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// Setup our socket (GCDAsyncSocket).
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    DDLogInfo(@"method : %@", THIS_METHOD);
    DDLogInfo(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    _isConnected = YES;
    [self.delegateForRootVC connected];
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    DDLogInfo(@"socketDidSecure:%p", sock);
    _isConnected = YES;
    
    NSString *requestStr = [NSString stringWithFormat:@"GET / HTTP/1.1\r\nHost: %@\r\n\r\n", _ipAdressTextField];
    NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [sock writeData:requestData withTimeout:-1 tag:0];
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}



- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    if(tag == GET_INVITE_TO_THE_GAME) {
        [self readDataWithTag:GET_INVITE_TO_THE_GAME];
    }
    switch (tag) {
        case GET_INVITE_TO_THE_GAME:
            [self readDataWithTag:GET_INVITE_TO_THE_GAME];
            break;
        case GET_ACCEPT:
            [self.delegateForGamerVC segueToGeneralViewController];
            
        default:
            break;
    }
    
    DDLogInfo(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    DDLogInfo(@"socket:%p didReadData:withTag:%ld", sock, tag);
    self.downloadedData = data;
    switch (tag) {
        case GET_INVITE_TO_THE_GAME:
            [self.delegateForGamerVC parseResponseFromServer];
            break;
            
        default:
            break;
    }
    
    NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    DDLogInfo(@"HTTP Response:\n%@", httpResponse);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    DDLogInfo(@"socketDidDisconnect:%p withError: %@", sock, err);
    _isConnected = NO;
    [self.delegateForRootVC returnOnPreviusView];
}



@end
