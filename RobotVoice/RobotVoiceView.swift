//
//  RobotVoiceView.swift
//  RobotVoice
//
//  Created by David Flores on 9/27/15.
//  Copyright © 2015 David Flores. All rights reserved.
//

import UIKit

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
private let voiceCount = 13;
private let layerCount : Int = voiceCount * 2 - 1;
private let layerSpacing : CGFloat = 10.0;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class RobotVoiceView : UIView
{
    // NSCoder
    public required init?(coder decoder : NSCoder)
    {
        let count = Int(44100 * frameDuration);
        circularBufferInt16AudioData = CircularBuffer<Int16>(count:count, repeatedValue:0);
        
        super.init(coder:decoder);
        
        initializeRobotVoiceView();
    }
    
    // UIView
    public override init(frame : CGRect)
    {
        let count = Int(44100 * frameDuration);
        circularBufferInt16AudioData = CircularBuffer<Int16>(count:count, repeatedValue:0);
        
        super.init(frame:frame);
        
        initializeRobotVoiceView();
    }
 
    public override func layoutSubviews() -> Void
    {
        super.layoutSubviews();
        
        layoutVoiceLayers();
    }

    public override func didMoveToWindow()
    {
        super.didMoveToWindow();

        displayLink?.invalidate();
        
        if ( self.window != nil )
        {
            displayLink = CADisplayLink(target:self, selector:Selector("didReceiveDisplayLinkUpdate:"));
            displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode:NSRunLoopCommonModes);
        }
    }
    
    // RobotVoiceView
    public func didReceiveAudioData(unsafePointerInt16AudioData : UnsafePointer<Int16>, count audioDataCount : UInt32)
    {
        let intAudioDataCount = Int(audioDataCount);

        circularBufferInt16AudioData.append(unsafePointerInt16AudioData, count:intAudioDataCount);
        
        let stride = circularBufferInt16AudioData.count / voiceLayerHeightArray.count;
        
        objc_sync_enter(self);
        
        for var index = 0; index < voiceLayerHeightArray.count; ++index
        {
            var circularBufferIndex = index * stride;
            if circularBufferIndex >= circularBufferInt16AudioData.count
            {
                circularBufferIndex = circularBufferInt16AudioData.count - 1;
            }
            
            voiceLayerHeightArray[index] =
                CGFloat(abs(circularBufferInt16AudioData[circularBufferIndex])) /
                CGFloat(Int16.max);
        }
        
        objc_sync_exit(self);
    }
    
    private func initializeRobotVoiceView() -> Void
    {
        self.backgroundColor = UIColor.blackColor();
        
        initializeVoiceLayerArray();
    }
    
    private func initializeVoiceLayerArray() -> Void
    {
        voiceLayerArray.reserveCapacity(layerCount);
        
        for var index = 0; index < layerCount; ++index
        {
            let layer = CALayer();

            layer.backgroundColor = UIColor.whiteColor().CGColor;
            
            self.layer.addSublayer(layer);

            voiceLayerArray.append(layer);
        }
    }

    private func layoutVoiceLayers() -> Void
    {
        let viewSize = self.frame.size;
        
        let layerWidth =
            (viewSize.width - layerSpacing * CGFloat(layerCount - 1)) /
            CGFloat(layerCount);
        
        var rectLayerFrame =
            CGRectMake(
                0,
                0,
                layerWidth,
                viewSize.height);
        
        for (index, voiceLayer) in voiceLayerArray.enumerate()
        {
            rectLayerFrame.origin.x =
                CGFloat(index) * (layerWidth + layerSpacing);
            
            voiceLayer.frame = rectLayerFrame;
        }
    }
    
    @objc private func didReceiveDisplayLinkUpdate(displayLink : CADisplayLink!) -> Void
    {
        CATransaction.begin();
     
        CATransaction.setAnimationDuration(0);
        
        objc_sync_enter(self);

        for (index, voiceLayer) in voiceLayerArray.enumerate()
        {
            var rectLayerFrame = voiceLayer.frame;
            
            let adjustedIndex =
                (index < voiceLayerHeightArray.count) ?
                    index :
                    2 * voiceLayerHeightArray.count - index - 2;
                    
            rectLayerFrame.size.height =
                voiceLayerHeightArray[adjustedIndex] * self.bounds.size.height;
            
            voiceLayer.frame = rectLayerFrame;
        }
        
        objc_sync_exit(self);

        CATransaction.commit();
    }
    
    private var frameDuration = 1.0 / 60.0;
    private let circularBufferInt16AudioData : CircularBuffer<Int16>;
    private var voiceLayerHeightArray = Array<CGFloat>(count:voiceCount, repeatedValue:0);
    private var voiceLayerArray = Array<CALayer>();
    private var displayLink : CADisplayLink?;
}
