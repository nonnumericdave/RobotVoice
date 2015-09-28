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
 
    public override func layoutSubviews()
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

    private func layoutVoiceLayers()
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
        
        for var index = 0; index < voiceLayerArray.count; ++index
        {
            rectLayerFrame.origin.x =
                CGFloat(index) * (layerWidth + layerSpacing);
            
            voiceLayerArray[index].frame = rectLayerFrame;
        }
    }
    
    private var voiceLayerArray : Array<CALayer> = []
}
