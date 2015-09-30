//
//  RobotVoiceView.swift
//  RobotVoice
//
//  Created by David Flores on 9/27/15.
//  Copyright © 2015 David Flores. All rights reserved.
//

import UIKit

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
private let layerCount : Int = 25;
private let layerSpacing : CGFloat = 10.0;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class RobotVoiceView : UIView
{
    // NSCoder
    public required init?(coder decoder: NSCoder)
    {
        super.init(coder:decoder);
        
        initializeRobotVoiceView();
    }
    
    // UIView
    public override init(frame:CGRect)
    {
        super.init(frame:frame);
        
        initializeRobotVoiceView();
    }
 
    public override func layoutSubviews() -> Void
    {
        super.layoutSubviews();
        
        layoutVoiceLayers();
    }

    // RobotVoiceView
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
    
    private var voiceLayerArray : Array<CALayer> = []
}
