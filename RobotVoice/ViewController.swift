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
private func AudioBuffersNeededForAudioBufferListSize(bufferListSize: Int) -> Int
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

        for captureDeviceFormat in audioCaptureDevice.formats as! [AVCaptureDeviceFormat]!
        {
            print("\(captureDeviceFormat)");
        }
        
        let audioCaptureDeviceOutput = AVCaptureAudioDataOutput();
        audioCaptureDeviceOutput.setSampleBufferDelegate(self, queue:dispatchQueue)

        guard captureSession.canAddOutput(audioCaptureDeviceOutput)
        else
        {
            return;
        }
        
        captureSession.addInput(audioCaptureDeviceInput);
        captureSession.addOutput(audioCaptureDeviceOutput);
    }
    
    internal override func viewDidAppear(animated: Bool)
    {
        captureSession.startRunning();
    }
    
    // AVCaptureAudioDataOutputSampleBufferDelegate
    internal func captureOutput(
        captureOutput: AVCaptureOutput!,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
        fromConnection connection: AVCaptureConnection!)
    {
        guard
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
            where CMFormatDescriptionGetMediaType(formatDescription) == kCMMediaType_Audio
        else
        {
            return;
        }
        
        let unsafePointerAudioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
        let audioStreamBasicDescription = unsafePointerAudioStreamBasicDescription.memory;
        guard
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
            audioStreamBasicDescription.mBitsPerChannel == 16
        else
        {
            return;
        }

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
        
        for audioBuffer in unsafeMutableAudioBufferListPointer
        {
            let unsafePointerInt16 = UnsafePointer<Int16>(audioBuffer.mData);
            
            assert( unsafePointerInt16 != nil );
        }
        
        free(unsafeMutableAudioBufferListPointer.unsafeMutablePointer);
    }
    
    // ViewController
    private var captureSession = AVCaptureSession();
    private let dispatchQueue = dispatch_queue_create("com.playingandsuffering.RobotVoice", DISPATCH_QUEUE_SERIAL);
}
