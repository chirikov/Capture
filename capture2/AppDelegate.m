//
//  AppDelegate.m
//  capture2
//
//  Created by Roman Chirikov on 8/2/13.
//  Copyright (c) 2013 Roman Chirikov. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

QTCaptureSession                       *mCaptureSession;
QTCaptureDeviceInput                   *mCaptureDeviceInput;
QTCaptureDeviceInput                   *mCaptureDeviceInput;
CVImageBufferRef                       mCurrentImageBuffer;
QTCaptureDecompressedVideoOutput       *mCaptureDecompressedVideoOutput;
CGFloat currentKernel[200*200];
CGFloat lastKernel[200*200];
NSColor* color;
NSPoint mouseLoc;
NSPoint screenPoint;
CGFloat err = 0;
CGFloat minerr = 200*200;
int minsy, minsx;
int i, j;
int sx, sy;
int kernelw = 40;
int skernelw;
int margin = 10;
bool kernelReady = false;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (IBAction)addFrame:(id)sender {
    NSError *error;
    mCaptureSession = [[QTCaptureSession alloc] init];
    BOOL success;
    
	//////list cameras
	NSArray *devices = [QTCaptureDevice inputDevices];
	
	for (QTCaptureDevice* device2 in devices) {
		NSLog(@"available device: %@", [device2 localizedDisplayName]);
	}
	
	
	//QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
	QTCaptureDevice *device = devices[1]; //3 for pocketcam
	
    success = [device open:&error];
    if (!success) {
        [[NSAlert alertWithError:error] runModal];
        return;
    }
    
    mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
    success = [mCaptureSession addInput:mCaptureDeviceInput error:&error];
    if (!success) {
        [[NSAlert alertWithError:error] runModal];
        return;
    }
    
    mCaptureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
    [mCaptureDecompressedVideoOutput setDelegate:self];
    success = [mCaptureSession addOutput:mCaptureDecompressedVideoOutput error:&error];
    if (!success) {
        [[NSAlert alertWithError:error] runModal];
        return;
    }
    
    [mCaptureView setCaptureSession:mCaptureSession];
    [mCaptureSession startRunning];
	
	skernelw = kernelw-2*margin;
	mouseLoc = [NSEvent mouseLocation];
}

- (IBAction)frame:(id)sender {
    /*
	//output currentKernel
	printf("Current kernel:\n");
	for(i = 0; i < kernelw; i++)
	{
		for(j = 0; j < kernelw; j++)
		{
			printf("%3.2f ", currentKernel[i*kernelw + j]);
		}
		printf("\n");
	}
	
	// output last kernel
	printf("Last kernel:\n");
	for(i = 0; i < (kernelw-2*margin); i++)
	{
		for(j = 0; j < (kernelw-2*margin); j++)
		{
			printf("%3.2f ", lastKernel[i*(kernelw-2*margin) + j]);
		}
		printf("\n");
	}
	*/
}

- (void)process
{
    CVImageBufferRef imageBuffer;
    @synchronized (self) {
        imageBuffer = CVBufferRetain(mCurrentImageBuffer);
    }
    if (imageBuffer)
	{
        NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:imageBuffer]];
        NSImage *image = [[NSImage alloc] initWithSize:[imageRep size]];
        [image addRepresentation:imageRep];
        //[img setImage:image];
        CVBufferRelease(imageBuffer);
        
        // crop
        NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(kernelw, kernelw)];
        [newImage lockFocus];
		[image
         drawInRect:NSMakeRect(0, 0, kernelw, kernelw)
         fromRect:NSMakeRect(20, 20, 8*kernelw, 8*kernelw)
         operation:NSCompositeSourceOver
         fraction:1.0
         ];
        [newImage unlockFocus];
        [img setImage:newImage];
        
        // compute shift
        NSBitmapImageRep* raw_img = [NSBitmapImageRep imageRepWithData:[newImage TIFFRepresentation]];
        
        // fill currentKernel (100x100)
        for(i = 0; i < kernelw; i++)
        {
            for(j = 0; j < kernelw; j++)
            {
                color = [raw_img colorAtX:i y:j];
                currentKernel[i*kernelw + j] = [color brightnessComponent];
            }
        }
		
        // lookup
        if(kernelReady)
        {
			//printf("work");
			minerr = skernelw*skernelw;
            for(sy = 0; sy < 2*margin; sy++)
            {
                for(sx = 0; sx < 2*margin; sx++)
                {
                    err = 0;
					// walk through lastKernel
                    for(i = 0; i < skernelw; i++)
                    {
                        for(j = 0; j < skernelw; j++)
                        {
                            if(lastKernel[i*skernelw + j] > currentKernel[(i+sy)*kernelw + j+sx])
								err += lastKernel[i*skernelw + j] - currentKernel[(i+sy)*kernelw + j+sx];
							else
								err += currentKernel[(i+sy)*kernelw + j+sx] - lastKernel[i*skernelw + j];
							//err += abs(lastKernel[i*skernelw + j] - currentKernel[(i+sy)*kernelw + j+sx]);
                        }
                    }
                    if(err < minerr)
                    {
                        minerr = err;
                        minsy = sy;
                        minsx = sx;
                    }
                }
            }
			
			[self.lminerr setStringValue:[NSString stringWithFormat:@"%3.2f", minerr]];
			[self.lminsx setStringValue:[NSString stringWithFormat:@"%d", minsx]];
			[self.lminsy setStringValue:[NSString stringWithFormat:@"%d", minsy]];
			if(minerr > skernelw * skernelw / 200)
			{
				screenPoint.x = mouseLoc.x + minsx-margin;
				screenPoint.y = (900 - mouseLoc.y) - (minsy - margin);
				if(screenPoint.x < 0) screenPoint.x = 0;
				if(screenPoint.y < 0) screenPoint.y = 0;
				if(screenPoint.x > 1440) screenPoint.x = 1440;
				if(screenPoint.y > 900) screenPoint.y = 900;
				CGWarpMouseCursorPosition(CGPointMake(screenPoint.x, screenPoint.y));
				mouseLoc.x = screenPoint.x;
				mouseLoc.y = 900 - screenPoint.y;
			}
        }
        
        // save kernel (80x80)
        for(i = 0; i < skernelw; i++)
        {
            for(j = 0; j < skernelw; j++)
            {
                lastKernel[i*skernelw + j] = currentKernel[(i+margin)*kernelw + j+margin];
            }
        }
		kernelReady = true;
    }
}

- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
    CVImageBufferRef imageBufferToRelease;
    
    CVBufferRetain(videoFrame);
    
    @synchronized (self) {
        imageBufferToRelease = mCurrentImageBuffer;
        mCurrentImageBuffer = videoFrame;
    }
    CVBufferRelease(imageBufferToRelease);
    
    [self process];
}

@end
