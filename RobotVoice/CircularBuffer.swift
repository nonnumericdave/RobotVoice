//
//  CircularBuffer.swift
//  RobotVoice
//
//  Created by David Flores on 9/30/15.
//  Copyright © 2015 David Flores. All rights reserved.
//

import Foundation

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class CircularBuffer<T> : Indexable
{
    // Indexable
    public typealias Index = Int;
    
    public var startIndex : Int
    {
        return 0;
    }
    
    public var endIndex : Int
    {
        return array.count;
    }
    
    public subscript(position : Int) -> T
    {
        return array[abs((position &+ bufferStartIndex) % array.count)];
    }
    
    // CircularBuffer
    public init(count : Int, repeatedValue : T)
    {
        array = Array<T>(count:count, repeatedValue:repeatedValue);
        bufferStartIndex = 0;
    }

    public func append(newElement : T) -> Void
    {
        array[bufferStartIndex] = newElement;
        bufferStartIndex = abs((1 &+ bufferStartIndex) % array.count);
    }

    public func append(unsafePointerData : UnsafePointer<T>, count : Int) -> Void
    {
        let unsafePointerDataCopy =
            (count > array.count) ?
                unsafePointerData.advancedBy(count - array.count) :
                unsafePointerData;

        let copyCount =
            (count > array.count) ?
                array.count :
                count;

        let unsafeBufferPointerData =
            UnsafeBufferPointer(start:unsafePointerDataCopy, count:copyCount);
        
        for (index, data) in unsafeBufferPointerData.enumerate()
        {
            array[abs((index &+ bufferStartIndex) % array.count)] = data;
        }
        
        bufferStartIndex = abs((copyCount &+ bufferStartIndex) % array.count);
    }
    
    public var count : Int
    {
        return array.count;
    }
    
    private var array : Array<T>;
    private var bufferStartIndex : Int;
}
