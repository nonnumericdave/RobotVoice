//
//  AudioProcessor.swift
//  RobotVoice
//
//  Created by David Flores on 10/4/15.
//  Copyright © 2015 David Flores. All rights reserved.
//

import Accelerate

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
private let sampleCount = 1024;
private var inverseDFTFactor = Float(2 * sampleCount);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class AudioProcessor : AudioDataSourceDelegate
{
    // AudioDataSourceDelegate
    internal func didReceiveAudioData(unsafePointerInt16AudioData : UnsafePointer<Int16>, count audioDataCount : UInt32) -> Void
    {
        var audioDataCountRemaining = Int(audioDataCount);
        
        while ( audioDataCountRemaining > 0 )
        {
            let spaceRemaining = sampleCount - audioData.count;
            let bufferCount = min(spaceRemaining, audioDataCountRemaining);
        
            let unsafeBufferPointerInt16AudioData =
                UnsafeBufferPointer(start:unsafePointerInt16AudioData, count:bufferCount);
        
            audioData.appendContentsOf(unsafeBufferPointerInt16AudioData);
            audioDataCountRemaining -= bufferCount;
        
            if ( audioData.count == sampleCount )
            {
                processAudioData();
            }
        }
    }
    
    // AudioProcessor
    internal init(delegate : AudioDataSourceDelegate)
    {
        self.delegate = delegate;
        
        forwardDFTSetup =
            vDSP_DFT_zrop_CreateSetup(
                nil,
                UInt(sampleCount),
                .FORWARD);
        
        inverseDFTSetup =
            vDSP_DFT_zrop_CreateSetup(
                forwardDFTSetup,
                UInt(sampleCount),
                .INVERSE);
        
        unsafeMutablePointerFloatAudioDataReal =
            UnsafeMutablePointer<Float>.alloc(sampleCount / 2);

        unsafeMutablePointerFloatAudioDataImaginary =
            UnsafeMutablePointer<Float>.alloc(sampleCount / 2);

        assert( forwardDFTSetup != nil );
        assert( inverseDFTSetup != nil );
        
        audioData.reserveCapacity(sampleCount);
    }
    
    deinit
    {
        vDSP_DFT_DestroySetup(forwardDFTSetup);
        vDSP_DFT_DestroySetup(inverseDFTSetup);

        unsafeMutablePointerFloatAudioDataReal.dealloc(sampleCount / 2);
        unsafeMutablePointerFloatAudioDataImaginary.dealloc(sampleCount / 2);
    }
    
    private func processAudioData() -> Void
    {
        assert( audioData.count == sampleCount );

        vDSP_vflt16(audioData,
                    2,
                    unsafeMutablePointerFloatAudioDataReal,
                    1,
                    UInt(sampleCount / 2));
        
        vDSP_vflt16(UnsafePointer(audioData).successor(),
                    2,
                    unsafeMutablePointerFloatAudioDataImaginary,
                    1,
                    UInt(sampleCount / 2));

        vDSP_DFT_Execute(forwardDFTSetup,
                         unsafeMutablePointerFloatAudioDataReal,
                         unsafeMutablePointerFloatAudioDataImaginary,
                         unsafeMutablePointerFloatAudioDataReal,
                         unsafeMutablePointerFloatAudioDataImaginary);
        
        vDSP_DFT_Execute(inverseDFTSetup,
                         unsafeMutablePointerFloatAudioDataReal,
                         unsafeMutablePointerFloatAudioDataImaginary,
                         unsafeMutablePointerFloatAudioDataReal,
                         unsafeMutablePointerFloatAudioDataImaginary);

        vDSP_vsdiv(unsafeMutablePointerFloatAudioDataReal,
                   1,
                   &inverseDFTFactor,
                   unsafeMutablePointerFloatAudioDataReal,
                   1,
                   UInt(sampleCount / 2));
        
        vDSP_vsdiv(unsafeMutablePointerFloatAudioDataImaginary,
                   1,
                   &inverseDFTFactor,
                   unsafeMutablePointerFloatAudioDataImaginary,
                   1,
                   UInt(sampleCount / 2));
        
        vDSP_vfix16(unsafeMutablePointerFloatAudioDataReal,
                    1,
                    &audioData,
                    2,
                    UInt(sampleCount / 2));

        vDSP_vfix16(unsafeMutablePointerFloatAudioDataImaginary,
                    1,
                    UnsafeMutablePointer(audioData).successor(),
                    2,
                    UInt(sampleCount / 2));

        unsafeMutablePointerFloatAudioDataReal.destroy(sampleCount / 2);
        unsafeMutablePointerFloatAudioDataImaginary.destroy(sampleCount / 2);
        
        delegate?.didReceiveAudioData(audioData, count:UInt32(sampleCount));
        
        audioData.removeAll(keepCapacity:true);
    }
    
    private weak var delegate : AudioDataSourceDelegate?;
    private var audioData = Array<Int16>();
    private var forwardDFTSetup : vDSP_DFT_Setup;
    private var inverseDFTSetup : vDSP_DFT_Setup;
    private var unsafeMutablePointerFloatAudioDataReal : UnsafeMutablePointer<Float>;
    private var unsafeMutablePointerFloatAudioDataImaginary : UnsafeMutablePointer<Float>;
}
