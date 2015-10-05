//
//  ViewController.swift
//  RobotVoice
//
//  Created by David Flores on 9/27/15.
//  Copyright © 2015 David Flores. All rights reserved.
//

import UIKit;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
internal class ViewController : UIViewController, AudioDataSourceDelegate
{
    // UIViewController
    internal override func viewDidLoad()
    {
        super.viewDidLoad();
        
        audioDataSource = AudioDataSource(delegate:self);
    }
    
    // AudioDataSourceDelegate
    internal func didReceiveAudioData(unsafePointerInt16AudioData : UnsafePointer<Int16>, count audioDataCount : UInt32)
    {
        guard let robotVoiceView = self.view as? RobotVoiceView
        else
        {
            return;
        }
        
        robotVoiceView.didReceiveAudioData(unsafePointerInt16AudioData, count:audioDataCount);
    }

    // ViewController
    private var audioDataSource : AudioDataSource?;
}
