//
//  RobotVoiceView.swift
//  RobotVoice
//
//  Created by David Flores on 9/27/15.
//  Copyright © 2015 David Flores. All rights reserved.
//

import UIKit

let layerWidth : CGFloat = 10.0;

class RobotVoiceView : UIView
{
    var layerArray : Array<CALayer> = []
    
    convenience
    init()
    {
        self.init(frame:CGRectZero);
    }
    
    override var frame : CGRect
    {
        willSet(rectFrame)
        {
            let newLayerCount = Int(rectFrame.width / layerWidth);
            assert( newLayerCount >= 0 );
            
            let oldLayerCount = layerArray.count;
            assert( oldLayerCount >= 0 );
            
            if ( newLayerCount > oldLayerCount )
            {
                layerArray.reserveCapacity(newLayerCount);
            
                for _ in (oldLayerCount + 1) ... newLayerCount
                {
                    let layer = CALayer();

                    layer.backgroundColor = UIColor.blackColor().CGColor;
                    
                    self.layer.addSublayer(layer);
                    layerArray.append(layer);
                }
            }
            else if ( newLayerCount < oldLayerCount )
            {
                for layer in layerArray.dropFirst(newLayerCount)
                {
                    layer.removeFromSuperlayer();
                }
                
                layerArray.removeRange(newLayerCount ... (oldLayerCount - 1));
            }
            
            for var index = 0; index < layerArray.count; ++index
            {
                let rectLayerFrame =
                    CGRectMake(
                        CGFloat(index) * layerWidth,
                        0,
                        layerWidth,
                        rectFrame.height);
                
                layerArray[index].frame = rectLayerFrame;
            }
        }
    }
}
