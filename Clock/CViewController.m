//
//  CViewController.m
//  Clock
//
//  Created by Tung Pham Thanh on 2/6/14.
//  Copyright (c) 2014 Tung Pham. All rights reserved.
//  Change something

#import "CViewController.h"

#define kRetryLimitation    3

@interface CViewController ()<NSURLConnectionDelegate, NSURLConnectionDataDelegate>{
    
    __weak IBOutlet UIButton *btnRetry;
    __weak IBOutlet UILabel *lblClock;
    NSMutableData *revData;
    NSInteger counter;
    NSDateFormatter *dateFormatter;
    NSTimeInterval diff;
    NSTimeInterval comparedTimeInterval;
    NSTimer *timer, *reloadTimer;
}

@end

@implementation CViewController
- (IBAction)retry:(id)sender {
    btnRetry.hidden = YES;
    [self startLoadingTime];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    counter = kRetryLimitation;
    [self startLoadingTime];
	// Do any additional setup after loading the view, typically from a nib.
}
- (void) startLoadingTime{
    counter --;
    if (counter < 0) {
        counter = kRetryLimitation;
        btnRetry.hidden = NO;
        return;
    }
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    NSURL *url = [NSURL URLWithString:@"http://staging-api.lovebyte.us/datetime"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request
                                                                  delegate:self
                                                          startImmediately:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) updateTime{
    NSDate *date = [NSDate date];
    NSTimeInterval timeInterval = [date timeIntervalSince1970];
    timeInterval -= diff;
    date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    lblClock.text = [dateFormatter stringFromDate:date];
}
#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse *res = (NSHTTPURLResponse*)response;
    if (res.statusCode == 200) {
        NSDate *date = [NSDate new];
        comparedTimeInterval = [date timeIntervalSince1970];
        revData = [NSMutableData new];
        return;
    }
    [self startLoadingTime];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [revData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSString *strDate = [[NSString alloc] initWithData:revData
                                              encoding:NSUTF8StringEncoding];
    strDate = [strDate stringByReplacingOccurrencesOfString:@"T"
                                                 withString:@" "];
    strDate = [strDate stringByReplacingOccurrencesOfString:@"Z"
                                                 withString:@""];
    NSDate *serverDate = [dateFormatter dateFromString:strDate];
    NSTimeInterval timeInterval = [serverDate timeIntervalSince1970];
    diff = comparedTimeInterval - timeInterval;
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                 target:self
                                               selector:@selector(updateTime)
                                               userInfo:nil
                                                repeats:YES];
    }
    //Update time from server after each 5 minutes
    [self performSelector:@selector(startLoadingTime)
               withObject:nil
               afterDelay:300];
    counter = kRetryLimitation;
}
@end
