//
//  ViewController.swift
//  RobotVoice
//
//  Created by David Flores on 9/27/15.
//  Copyright © 2015 David Flores. All rights reserved.
//

import AVFoundation;
import CoreMedia;
import UIKit;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
private func AudioBuffersNeededForAudioBufferListSize(bufferListSize : Int) -> Int
{
    let oneAudioBufferListSize = AudioBufferList.sizeInBytes(maximumBuffers:1);
    let twoAudioBufferListSize = AudioBufferList.sizeInBytes(maximumBuffers:2);

    let sizePerAudioBuffer = twoAudioBufferListSize - oneAudioBufferListSize;
    let baseAudioBufferListSize = oneAudioBufferListSize - sizePerAudioBuffer;

    return (bufferListSize - baseAudioBufferListSize) / sizePerAudioBuffer;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
internal class ViewController : UIViewController, AVCaptureAudioDataOutputSampleBufferDelegate
{
    // UIViewController
    internal override func viewDidLoad()
    {
        super.viewDidLoad()

		dispatch_async(
			dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0),
			{
				[unowned self] in
				
				self.initializeCaptureSession();
			});
	}

    // AVCaptureAudioDataOutputSampleBufferDelegate
    internal func captureOutput(
        captureOutput : AVCaptureOutput!,
        didOutputSampleBuffer sampleBuffer : CMSampleBuffer!,
        fromConnection connection : AVCaptureConnection!)
    {
		objc_sync_enter(self);
		guard audioFormatIsSupported
		else
		{
			objc_sync_exit(self);
			return;
		}
		objc_sync_exit(self);

        var bufferListSizeNeeded : Int = 0;
        var audioBufferList = AudioBufferList();
        var blockBuffer : CMBlockBuffer?;
        
        guard
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                sampleBuffer,
                &bufferListSizeNeeded,
                &audioBufferList,
                0,
                kCFAllocatorSystemDefault,
                kCFAllocatorSystemDefault,
                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                &blockBuffer) == kCMSampleBufferError_ArrayTooSmall
        else
        {
            return;
        }
        
        let maximumAudioBuffersNeeded =
            AudioBuffersNeededForAudioBufferListSize(bufferListSizeNeeded);
        
        let unsafeMutableAudioBufferListPointer =
            AudioBufferList.allocate(maximumBuffers:maximumAudioBuffersNeeded);
        
        guard
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                sampleBuffer,
                &bufferListSizeNeeded,
                unsafeMutableAudioBufferListPointer.unsafeMutablePointer,
                AudioBufferList.sizeInBytes(maximumBuffers:maximumAudioBuffersNeeded),
                kCFAllocatorSystemDefault,
                kCFAllocatorSystemDefault,
                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                &blockBuffer) == noErr
        else
        {
            return;
        }
        
        let robotVoiceView = view as! RobotVoiceView;
        
        for audioBuffer in unsafeMutableAudioBufferListPointer
        {
            let unsafePointerInt16AudioData = UnsafePointer<Int16>(audioBuffer.mData);

            assert( audioBuffer.mDataByteSize % 2 == 0 );
            let audioDataCount = audioBuffer.mDataByteSize / 2;
            
            robotVoiceView.didReceiveAudioData(unsafePointerInt16AudioData, count:audioDataCount);
            
            assert( unsafePointerInt16AudioData != nil );
        }
        
        free(unsafeMutableAudioBufferListPointer.unsafeMutablePointer);
    }
    
    // ViewController
	deinit
	{
		let defaultNotificationCenter = NSNotificationCenter.defaultCenter();
		for notificationObserver in notificationObserverArray
		{
			defaultNotificationCenter.removeObserver(notificationObserver);
		}
	}
	
	private func initializeCaptureSession() -> Void
	{
		let defaultNotificationCenter = NSNotificationCenter.defaultCenter();
		
		notificationObserverArray.append(
			defaultNotificationCenter.addObserverForName(
				AVCaptureSessionDidStartRunningNotification,
				object:captureSession,
				queue:nil,
				usingBlock:
				{
					[unowned self] (notification) -> Void in
					
					self.addObserversToCaptureInputPorts();
					
					self.validateAudioFormat();
				}));
		
		notificationObserverArray.append(
			defaultNotificationCenter.addObserverForName(
				AVCaptureSessionDidStopRunningNotification,
				object:captureSession,
				queue:nil,
				usingBlock:
				{
					[unowned self] (notification) -> Void in
					
					objc_sync_enter(self);
					self.audioFormatIsSupported = false;
					objc_sync_exit(self);
				}));

        guard let dispatchQueue = self.dispatchQueue
        else
        {
            return;
        }
        
        guard
            let audioCaptureDeviceArray = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio)
            where audioCaptureDeviceArray.count > 0,
            let audioCaptureDevice = audioCaptureDeviceArray[0] as? AVCaptureDevice,
            let audioCaptureDeviceInput = try? AVCaptureDeviceInput(device:audioCaptureDevice)
            where captureSession.canAddInput(audioCaptureDeviceInput)
        else
        {
            return;
        }

        let audioCaptureDataOutput = AVCaptureAudioDataOutput();
        audioCaptureDataOutput.setSampleBufferDelegate(self, queue:dispatchQueue)

        guard captureSession.canAddOutput(audioCaptureDataOutput)
        else
        {
            return;
        }
        
        captureSession.addInput(audioCaptureDeviceInput);
        captureSession.addOutput(audioCaptureDataOutput);

		captureSession.startRunning();
	}
	
	private func enumerateAudioCaptureInputPorts(@noescape block : (AVCaptureInputPort) -> Void) -> Void
	{
		objc_sync_enter(self);
		guard
			captureSession.outputs.count == 1,
			let audioCaptureDataOutput = captureSession.outputs[0] as? AVCaptureAudioDataOutput,
			let captureConnectionArray = audioCaptureDataOutput.connections as? [AVCaptureConnection]
		else
		{
			objc_sync_exit(self);
			return;
		}
		objc_sync_exit(self);
		
		for captureConnection in captureConnectionArray
		{
			guard
				let captureInputPortArray = captureConnection.inputPorts as? [AVCaptureInputPort]
			else
			{
				continue;
			}
			
			for captureInputPort in captureInputPortArray
			where captureInputPort.mediaType == AVMediaTypeAudio
			{
				block(captureInputPort);
			}
		}
	}
	
	private func addObserversToCaptureInputPorts() -> Void
	{
		let defaultNotificationCenter = NSNotificationCenter.defaultCenter();

		enumerateAudioCaptureInputPorts(
		{
			[unowned self] (captureInputPort) -> Void in
			
			self.notificationObserverArray.append(
				defaultNotificationCenter.addObserverForName(
					AVCaptureInputPortFormatDescriptionDidChangeNotification,
					object:captureInputPort,
					queue:nil,
					usingBlock:
					{
						[unowned self] (notification) -> Void in
						
						self.validateAudioFormat();
					}));
		});
	}
	
	private func validateAudioFormat() -> Void
	{
		objc_sync_enter(self);
		audioFormatIsSupported = false;
		objc_sync_exit(self);
		
		var audioFormatIsSupportedUpdated = true;
		
		enumerateAudioCaptureInputPorts(
		{
			(captureInputPort) -> Void in
			
			guard
				let formatDescription = captureInputPort.formatDescription
			else
			{
				return;
			}
			
			let unsafePointerAudioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
			
			let audioStreamBasicDescription = unsafePointerAudioStreamBasicDescription.memory;

			let audioFormatIsSupported =
				audioStreamBasicDescription.mFormatID == kAudioFormatLinearPCM &&
					audioStreamBasicDescription.mSampleRate == 44100.0 &&
					audioStreamBasicDescription.mFormatFlags ==
						(kAudioFormatFlagIsSignedInteger |
							kAudioFormatFlagsNativeEndian |
							kAudioFormatFlagIsPacked) &&
					audioStreamBasicDescription.mBytesPerPacket == 2 &&
					audioStreamBasicDescription.mFramesPerPacket == 1 &&
					audioStreamBasicDescription.mBytesPerFrame == 2 &&
					audioStreamBasicDescription.mChannelsPerFrame == 1 &&
					audioStreamBasicDescription.mBitsPerChannel == 16;
			
			audioFormatIsSupportedUpdated = audioFormatIsSupportedUpdated && audioFormatIsSupported;
		});
		
		objc_sync_enter(self);
		audioFormatIsSupported = audioFormatIsSupportedUpdated;
		objc_sync_exit(self);
	}
	
	private var notificationObserverArray = Array<NSObjectProtocol>();
	private var audioFormatIsSupported = false;
    private var captureSession = AVCaptureSession();
    private let dispatchQueue = dispatch_queue_create("com.playingandsuffering.RobotVoice", DISPATCH_QUEUE_SERIAL);
}
