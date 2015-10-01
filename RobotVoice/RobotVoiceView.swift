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
        super.init(coder:decoder);
        
        initializeRobotVoiceView();
    }
    
    // UIView
    public override init(frame : CGRect)
    {
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
        
        objc_sync_enter(self);

        var indexOfNextSample = countToNextSample;
        
        while indexOfNextSample < intAudioDataCount
        {
            let nextAbsoluteSample =
                (unsafePointerInt16AudioData[indexOfNextSample] == Int16.min) ?
                    Int16.max :
                    abs(unsafePointerInt16AudioData[indexOfNextSample]);
            
            let normalizedSample =
                CGFloat(nextAbsoluteSample) / CGFloat(Int16.max);
            
            voiceLayerHeightCircularBuffer.append(normalizedSample);
            
            indexOfNextSample += sampleStride;
        }
        
        countToNextSample = indexOfNextSample - intAudioDataCount;
        
        objc_sync_exit(self);
    }
    
    private func initializeRobotVoiceView() -> Void
    {
        self.backgroundColor = UIColor.blackColor();
        
        initializeVoiceLayerArray();
    }
    
    private func initializeVoiceLayerArray() -> Void
    {
        let samplesPerFrameCount = Int(44100 * frameDuration);
        sampleStride = samplesPerFrameCount / voiceCount;
        
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
            
            let adjustedIndex =
                (index < voiceLayerHeightCircularBuffer.count) ?
                    index :
                    2 * voiceLayerHeightCircularBuffer.count - index - 2;
            
            let transform3d =
                CATransform3DMakeScale(
                    1,
                    voiceLayerHeightCircularBuffer[adjustedIndex],
                    1);
            
            voiceLayer.transform = transform3d;
        }
    }
    
    @objc private func didReceiveDisplayLinkUpdate(displayLink : CADisplayLink!) -> Void
    {
        CATransaction.begin();
     
        CATransaction.setDisableActions(true);
        
        objc_sync_enter(self);

        for (index, voiceLayer) in voiceLayerArray.enumerate()
        {
            let adjustedIndex =
                (index < voiceLayerHeightCircularBuffer.count) ?
                    index :
                    2 * voiceLayerHeightCircularBuffer.count - index - 2;

            let transform3d =
                CATransform3DMakeScale(
                    1,
                    voiceLayerHeightCircularBuffer[adjustedIndex],
                    1);
            
            voiceLayer.transform = transform3d;
            
            voiceLayer.backgroundColor = UIColor(white:voiceLayerHeightCircularBuffer[adjustedIndex], alpha:1).CGColor;
        }
        
        objc_sync_exit(self);

        CATransaction.commit();
    }
    
    private var frameDuration = 1.0 / 60.0;
    private var countToNextSample : Int = 0;
    private var sampleStride : Int = 0;
    private var voiceLayerHeightCircularBuffer = CircularBuffer<CGFloat>(count:voiceCount, repeatedValue:0);
    private var voiceLayerArray = Array<CALayer>();
    private var displayLink : CADisplayLink?;
}
