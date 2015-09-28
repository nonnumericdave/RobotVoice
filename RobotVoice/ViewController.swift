//
//  ViewController.swift
//  RobotVoice
//
//  Created by David Flores on 9/27/15.
//  Copyright © 2015 David Flores. All rights reserved.
//

import AVFoundation
import UIKit

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
internal class ViewController : UIViewController, AVCaptureAudioDataOutputSampleBufferDelegate
{
    // UIViewController
    internal override func viewDidLoad()
    {
        super.viewDidLoad()
        
        guard
            let audioCaptureDeviceArray = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio)
            where audioCaptureDeviceArray.count > 0,
            let audioCaptureDeviceInput = try? AVCaptureDeviceInput(device:audioCaptureDeviceArray[0] as! AVCaptureDevice)
            where captureSession.canAddInput(audioCaptureDeviceInput)
            else
        {
            return;
        }

        let audioCaptureDeviceOutput = AVCaptureAudioDataOutput();
        audioCaptureDeviceOutput.setSampleBufferDelegate(
            self, queue:
            dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0))

        guard captureSession.canAddOutput(audioCaptureDeviceOutput) else
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
    func captureOutput(
        captureOutput: AVCaptureOutput!,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
        fromConnection connection: AVCaptureConnection!)
    {
    }
    
    // ViewController
    private var captureSession = AVCaptureSession()
}
