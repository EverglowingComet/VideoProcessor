//
//  ViewController.m
//  MergeImageVideo
//
//  Created by user on 4/22/17.
//  Copyright © 2017 user. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


- (IBAction)onBtnMerge:(id)sender {
	[self mergeVideoAndGif];
}


// MARK: - private methods
- (CALayer *)createImageLayer:(CALayer *)parent rect:(CGRect)rect name:(NSString *)rcID {
	CALayer *layer = [CALayer new];
	layer.frame = rect;
	
	layer.contents = (id)[[UIImage imageNamed:rcID] CGImage];
	
	[parent addSublayer:layer];
	
	return layer;
}

- (CALayer *)createGifLayer:(CALayer *)parent rect:(CGRect)rect url:(NSURL *)url {
	CALayer *layer = [CALayer new];
	layer.frame = rect;
	
	[self startGifAnimationWithURL:url inLayer:layer];
	[parent addSublayer:layer];
	
	return layer;
}


- (void)mergeVideoAndGif {
	AVMutableComposition *composition = [AVMutableComposition composition];
	AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
	
	CMTime nextTime = kCMTimeZero;
	
	videoComposition.renderSize = CGSizeMake(720, 720);
	videoComposition.frameDuration = CMTimeMake(1, 30);
	
	
	AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"]]];
	AVAssetTrack *assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
	
	[videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetVideoTrack atTime:kCMTimeZero error:nil];
	
	nextTime = CMTimeAdd(nextTime, asset.duration);
	
	[videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetVideoTrack atTime:nextTime error:nil];
	
	
	CALayer *parentLayer = [CALayer new];
	parentLayer.frame = CGRectMake(0, 0, 720, 720);
	
	CALayer *videoLayer = [CALayer new];
	videoLayer.frame = CGRectMake(0, 0, 720, 720);
	
	// add gif layer to video
	CALayer *overlayLayer = [CALayer new];
	overlayLayer.frame = CGRectMake(0,258, 166, 166);
	
	CALayer *overlayLayer1 = [CALayer new];
	overlayLayer1.frame = CGRectMake(270,278, 166, 166);
	
	CALayer *overlayLayer2 = [CALayer new];
	overlayLayer2.frame = CGRectMake(450,258, 166, 166);
	
	CALayer *overlayLayer3 = [CALayer new];
	overlayLayer3.frame = CGRectMake(250,258, 166, 166);
	
	CALayer *overlayLayer4 = [CALayer new];
	overlayLayer4.frame = CGRectMake(250,258, 166, 166);
	
	CALayer *imageLayer = [CALayer new];
	imageLayer.frame = CGRectMake(100, 100, 400, 400);
	
	[parentLayer addSublayer:videoLayer];
	
	[parentLayer addSublayer:imageLayer];
	imageLayer.contents = (id)[[UIImage imageNamed:@"image"] CGImage];
	
	AVMutableVideoCompositionLayerInstruction *layerInstruction =
	[AVMutableVideoCompositionLayerInstruction
	 videoCompositionLayerInstructionWithAssetTrack:videoTrack];
	
	[layerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
	
	NSLog(@"asset duration == %f",CMTimeGetSeconds(asset.duration));
	NSLog(@"composition duration == %f",CMTimeGetSeconds(composition.duration));
	
	AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
	instruction.layerInstructions = [NSArray arrayWithObjects:layerInstruction, nil];
	videoComposition.instructions = [NSArray arrayWithObjects:instruction, nil];
	
	NSURL *fileUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"gif" ofType:@"gif"]];
	
	[self startGifAnimationWithURL:fileUrl inLayer:overlayLayer];
	
	NSURL *fileUrl1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"gif" ofType:@"gif"]];
	
	[self startGifAnimationWithURL:fileUrl1 inLayer:overlayLayer1];
	
	[self startGifAnimationWithURL:fileUrl inLayer:overlayLayer2];
	
	[self startGifAnimationWithURL:fileUrl inLayer:overlayLayer3];
	[self startGifAnimationWithURL:fileUrl inLayer:overlayLayer4];
	
	[parentLayer addSublayer:overlayLayer];
	[parentLayer addSublayer:overlayLayer1];
	[parentLayer addSublayer:overlayLayer2];
	[parentLayer addSublayer:overlayLayer3];
	[parentLayer addSublayer:overlayLayer4];
	
	videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
									  videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
	
	NSString *Directorypath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/VideoEditor"];
	NSLog(@"Directory Path = %@",Directorypath);
	if (![[NSFileManager defaultManager] fileExistsAtPath:Directorypath])
		[[NSFileManager defaultManager] createDirectoryAtPath:Directorypath withIntermediateDirectories:NO attributes:nil error:nil];
	
	NSString *outputPath = [Directorypath stringByAppendingPathComponent:@"camera.mov"];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
	{
		[[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
	}
	
	NSLog(@"path == %@",outputPath);
	
	NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
	
	AVAssetExportSession *exporter1 = [[AVAssetExportSession alloc] initWithAsset:composition
																	   presetName:AVAssetExportPresetHighestQuality];
	exporter1.outputURL=outputURL;
	exporter1.outputFileType = AVFileTypeQuickTimeMovie;
	exporter1.videoComposition = videoComposition;
	[exporter1 exportAsynchronouslyWithCompletionHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			
			dispatch_async(dispatch_get_main_queue(), ^{
				//Call when finished
				//[self exportDidFinish:exporter];
				//                [KVNProgress dismiss];
			});
			switch ([exporter1 status]) {
				case AVAssetExportSessionStatusFailed:
					NSLog(@"Export failed: %@", [[exporter1 error] description]);
					break;
				case AVAssetExportSessionStatusCancelled:
					NSLog(@"Export canceled");
					break;
				default:
					NSLog(@"Finished");
					
					dispatch_async(dispatch_get_main_queue(), ^{
						
						NSURL *videoURL = outputURL;
						AVPlayer *player = [AVPlayer playerWithURL:videoURL];
						AVPlayerViewController *playerViewController = [AVPlayerViewController new];
						playerViewController.player = player;
						[self presentViewController:playerViewController animated:YES completion:nil];
						
						
						//                        [NSGIF createGIFfromURL:videoURL withFrameCount:30 delayTime:.010 loopCount:0 completion:^(NSURL *GifURL) {
						//                            NSLog(@"Finished generating GIF: %@", GifURL);
						//                        }];
						
					});
					break;
			}
		});
	}];
}

- (void)startGifAnimationWithURL:(NSURL *)url inLayer:(CALayer *)layer
{
	CAKeyframeAnimation * animation = [self animationForGifWithURL:url];
	[layer addAnimation:animation forKey:@"contents"];
}

- (CGImageRef)resizeCGImage:(CGImageRef)image toScale:(int)scale {
	NSInteger width = CGImageGetWidth(image) / scale;
	NSInteger height = CGImageGetWidth(image) / scale;
	
	// create context, keeping original image properties
	CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
	CGContextRef context = CGBitmapContextCreate(NULL, width, height,
												 CGImageGetBitsPerComponent(image),
												 CGImageGetBytesPerRow(image),
												 colorspace,
												 CGImageGetAlphaInfo(image));
	CGColorSpaceRelease(colorspace);
	
	
	if (context == NULL)
		return nil;
	
	// draw image to context (resizing it)
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
	// extract resulting image from context
	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	
	return imgRef;
}

- (CAKeyframeAnimation *)animationForGifWithURL:(NSURL *)url
{
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	
	NSMutableArray * frames = [NSMutableArray new];
	NSMutableArray *delayTimes = [NSMutableArray new];
	
	CGFloat totalTime = 0.0;
	CGFloat gifWidth;
	CGFloat gifHeight;
	
	CGImageSourceRef gifSource = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	
	// get frame count
	size_t frameCount = CGImageSourceGetCount(gifSource);
	for (size_t i = 0; i < frameCount; ++i)
	{
		// get each frame
		CGImageRef frame = CGImageSourceCreateImageAtIndex(gifSource, i, NULL);
		[frames addObject:(__bridge id)frame];
		CGImageRelease(frame);
		
		// get gif info with each frame
		NSDictionary *dict = (NSDictionary*)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(gifSource, i, NULL));
		NSLog(@"kCGImagePropertyGIFDictionary %@", [dict valueForKey:(NSString*)kCGImagePropertyGIFDictionary]);
		
		// get gif size
		gifWidth = [[dict valueForKey:(NSString*)kCGImagePropertyPixelWidth] floatValue];
		gifHeight = [[dict valueForKey:(NSString*)kCGImagePropertyPixelHeight] floatValue];
		
		// kCGImagePropertyGIFDictionary中kCGImagePropertyGIFDelayTime，kCGImagePropertyGIFUnclampedDelayTime值是一样的
		NSDictionary *gifDict = [dict valueForKey:(NSString*)kCGImagePropertyGIFDictionary];
		NSNumber *frameDuration = [gifDict valueForKey:(NSString*)kCGImagePropertyGIFUnclampedDelayTime];
		if (!frameDuration) {
			frameDuration = [gifDict valueForKey:(NSString*)kCGImagePropertyGIFDelayTime];
		}
		
		[delayTimes addObject:frameDuration];
		
		totalTime = totalTime + frameDuration.floatValue;
	}
	
	if (gifSource)
	{
		CFRelease(gifSource);
	}
	
	NSMutableArray *times = [NSMutableArray arrayWithCapacity:3];
	CGFloat currentTime = 0;
	NSInteger count = delayTimes.count;
	for (int i = 0; i < count; ++i)
	{
		[times addObject:[NSNumber numberWithFloat:(currentTime / totalTime)]];
		currentTime += [[delayTimes objectAtIndex:i] floatValue];
	}
	
	NSMutableArray *images = [NSMutableArray arrayWithCapacity:3];
	for (int i = 0; i < count; ++i)
	{
		[images addObject:[frames objectAtIndex:i]];
	}
	
	animation.beginTime = /*AVCoreAnimationBeginTimeAtZero*/3;
	animation.keyTimes = times;
	animation.values = images;
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	animation.duration = totalTime;
	animation.removedOnCompletion = NO;
	animation.repeatCount = HUGE_VALF;
	
	return animation;
}

@end
