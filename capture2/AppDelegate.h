//
//  AppDelegate.h
//  capture2
//
//  Created by Roman Chirikov on 8/2/13.
//  Copyright (c) 2013 Roman Chirikov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <math.h>
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSImageView *img;
	IBOutlet NSImageView *img2;
    IBOutlet QTCaptureView *mCaptureView;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)addFrame:(id)sender;
- (IBAction)frame:(id)sender;
- (void)process;

@property (weak) IBOutlet NSTextField *lminsy;
@property (weak) IBOutlet NSTextField *lminsx;
@property (weak) IBOutlet NSTextField *lminerr;

@end
