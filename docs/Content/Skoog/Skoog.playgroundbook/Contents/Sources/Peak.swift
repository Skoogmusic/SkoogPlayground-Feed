//
//  Peak.swift
//  Skwitch
//
//  Created by David Skulina on 11/09/2016.
//  Copyright © 2016 Skoogmusic Ltd. All rights reserved.
//

import Foundation

let peak = Peak()

public class Peak: NSObject {
	var max = 0.0
    let absMax = 0.999999
    let nearMax = 0.75
    var restInput = 0.0
    var attack = 0.0
    let restThresh = 0.00001
    var closeThresh = 0.0
    var lowPeak = false
	var peakTick = 0
    var peakTime = 0.0
    var predictPeak = false
    
    public class var sharedInstance : Peak {
        return peak
    }
    
    public enum PeakMode : Int{
        case nonpredictive = 0
        case predictive
    }
    
    public enum State : Int{
        case atRest = 0
        case attacking
        case releasing
        case relaxing
    }
    
	public struct Displacement {
		var current = 0.0
		var last = 0.0
        func delta() -> Double{
           return current - last
        }
	}
    
	public struct Velocity {
		var current = 0.0
		var last = 0.0
        func delta() -> Double{
            return current - last
        }
	}
    
	public struct Acceleration {
		var current = 0.0
		var last = 0.0
        func delta() -> Double{
            return current - last
        }
    }
    
    var displacement = Displacement()
	var velocity  = Velocity()
    var acceleration = Acceleration()
	var state = State.atRest
    var peakMode = PeakMode.predictive

    override init() {
        super.init()
        displacement = Displacement(current:0.0, last: 0.0)
        velocity = Velocity()
        acceleration = Acceleration()
        closeThresh = 2 * restThresh
    }

//    public var attackState = state.atRest
    public func reset() {
        max = 0.0
        state = .atRest
    }
    
    public func detect (input:Double, dT: TimeInterval) -> Double? {
        var output : Double? = nil
        var currentInput = input
        velocity.current = currentInput - displacement.last
        acceleration.current = velocity.current - velocity.last

        switch state {
            case .atRest:

                displacement.current    =   0.0 // input
                displacement.last       =   0.0
                velocity.current        =   0.0 //displacement.current/dT
                velocity.last           =   0.0
                acceleration.last       =   0.0
                acceleration.current    =   0.0 //velocity.current/dT
//                previousTime            =   now
                peakTick                =   0
                peakTime                =   0.0;
                restInput               =   input
                attack                  =   0.0

                if currentInput > max { // maxvalue inits as 0.0
                    max = displacement.current
                    state = .attacking
                }
            break
            
        case .attacking:
            if currentInput < max {
                if currentInput > (0.8 * restThresh) {
                    state = .releasing
                }
                else {
                    state = .releasing
                    output =  0.0
                }
                
                //	 The conditional assignment corrects a problem with the previous code,
                //	 whereby it could take an extra cycle to move from attacking to atRest
                //	 states, thus causing us to be even later in finding some peaks
                //
                //	 This is handled the same in either mode. If we're in predictive mode and
                //	 get into this block, it means we didn't predict in advance.
                //	 Better luck next time.
                //
                if currentInput <= restThresh {
                    lowPeak = true;
                }
                else {
                    lowPeak = false
                }
                output =  max
            }
            else {				//	SIGNAL IS STILL INCREASING
                max = currentInput
                
                if peakTick < 2 {
                    peakTick += 1
                    peakTime += dT
					
					
					//TODO: adjust this section for firmware version
                    if peakTick == 2 {
                        if (peakTime < 0.016) {
                            peakTime = 1.0
                        }
                        else {
                            peakTime = 0.5
                        }
                        
//                        attack = 50.0 * (0.33333333 * (restInput + velocity.last + velocity.current) + 0.25 * (acceleration.current + acceleration.last))
//                        attack = 1.0 * peakTime * 2.4746349 * pow(attack, 1.977)  ; //FUDGE FIX
                        
                        attack = 5 * currentInput
                        //attack = 2 * currentInput + (velocity.current * (1.0/peakTime) + 0.5 * acceleration.current * (1.0/(peakTime * peakTime)))

                        
                        
                        state = .releasing
                        output =  attack < 1.0 ? attack : 0.999999
                    }
                }
                else {
                    if peakMode == .predictive {
                        // Extra tests in predictive mode
                        var predictPeak = false
                        let nextDelta = velocity.current + 0.5 * acceleration.current
                        
                        //                          1:	If we add current acceleration to current velocity, we can expect the
                        //                                    next sampled input  to be lower than the current value. That is,
                        //                                    this must be the peak!
                        
                        if nextDelta < 0.0 {
                            predictPeak = true
                        }
                            //                         2:	Check if the next value is likely to be near to or above the maximum
                            //                                value.
                        else {
                            if currentInput + nextDelta >= nearMax {
                                predictPeak = true
                                
                                currentInput += 0.5 * nextDelta
                                if displacement.current > absMax {
                                    displacement.current = absMax
                                }
                            }
                        }
                        
                        if predictPeak {
                            output = currentInput
                            state = .releasing
                            if currentInput <= restThresh {
                                lowPeak = true
                            }
                            else {
                                lowPeak = false
                            }
                        }
                    }
                }
            }
            break
        case .releasing:
            //                releaseTime = NSDate()
            if currentInput <= 0.8 * restThresh { //prev 0.8 was 1.0
                //		This is the only place where we call outlet_float directly because we do
                //		*not* want to update the stroke time value.
                
                if !lowPeak {
                    state = .relaxing
                    output =  0.0 //noteoff
                }
                else{
                    if (currentInput < 0.65 * restThresh){  //prev 0.65 was 0.1
                        state = .relaxing
                        output = 0.0 //noteoff
                    }
                }
            }
            break
        case .relaxing:
            if currentInput > 1.2 * restThresh && !lowPeak {
                max = 0.0
                state = .attacking
                output = nil
            }
            break
            
        }
        displacement.last   = currentInput
        velocity.last       = velocity.current
        acceleration.last   = acceleration.current
        //        previousTime		= now;
        return output
    }
}
