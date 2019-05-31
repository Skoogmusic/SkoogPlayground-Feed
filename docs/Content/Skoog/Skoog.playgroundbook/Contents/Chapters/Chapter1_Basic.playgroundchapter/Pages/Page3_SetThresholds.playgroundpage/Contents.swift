//#-hidden-code
/*
 Copyright (C) 2017 Skoogmusic Ltd. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information.
 
 */
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
**Goal:** Learn how to use a threshold to adjust the responsiveness of your Skoog.

Skoog is very sensitive and sometimes you'll want to decide how hard or soft you want to press before something happens.

 1. Press "Run my Code."
 2. Watch the graph as you press the Skoog.
 3. Try to make the colored dots go higher than the dashed line. What happens to the sound?

The dashed line represents a [threshold](glossary://threshold). In coding, thresholds are used to change how a program responds to new data. In our case, we use it to play a note.
 
  * callout(New Concept - Squeeze Events):
 
     Notice how the dots change color and height as you squeeze? Each new dot represents a new **squeeze event** from the Skoog. More on this later.
 
 
 **Challenge:** Change the threshold values below to get a feel for how the threshold affects the response. Keep it between 0.0 and 1.0!
 
 */
//#-hidden-code

import UIKit
import PlaygroundSupport
import CoreAudioKit
import SpriteKit
import SceneKit

PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

public class skoogContents: PlaygroundViewController {
    //#-end-hidden-code
    //#-code-completion(everything, hide)
    //#-hidden-code
func setup() {
changeAlpha = false
growCircle  = false
playNotes = true

var thresholds : [Double]
var test : Double
    
if let storedValue = PlaygroundKeyValueStore.current["testFloat"],
    case .floatingPoint(let value) = storedValue {
    test = value
}
    
if let storedValues = PlaygroundKeyValueStore.current["thresholds"],
    case .array(let values) = storedValues {
//        thresholds = values
}

// Show the new Skoog Plotter
drawGraph = true

// Do you want to show labels onscreen?
showSqueezeLabel = true
    
//#-end-hidden-code
setThresholds(red:    /*#-editable-code */0.2/*#-end-editable-code*/,
              blue:   /*#-editable-code */0.2/*#-end-editable-code*/,
              yellow: /*#-editable-code */0.2/*#-end-editable-code*/,
              green:  /*#-editable-code */0.2/*#-end-editable-code*/,
              orange: /*#-editable-code */0.2/*#-end-editable-code*/)
    
//#-hidden-code
}
    
    
public override func peak(_ side: Side,_ peak: Double) {
    noteOn(sideIndex:side.index, velocity: peak)
}

public override func continuous(_ side: Side) {
    super.continuous(side)
}

public override func release(_ side: Side) {
    super.release(side)
    //readyToPlay = true
}
}
let contents	=	skoogContents()
contents.setSound(.timpani)
contents.setup()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.rectangle.rectangle?.sceneDescription = NSLocalizedString("A graph showing squeeze data from your Skoog is displayed.  As you squeeze the Skoog, the color of the data changes. The squeeze data moves higher or lower on the screen depending on how hard you press the Skoog.  There is a horizontal line across the graph, indicating a threshold level that can be adjusted in your code.  A sound will be triggered when the squeeze data goes higher than the threshold.", comment: "live view 3 label")
contents.setBackgroundGradient(gradient: .gradient6)

PlaygroundPage.current.liveView = contents

var taskComplete : Bool = false

if  contents.red.threshold != 0.2 &&
    contents.blue.threshold != 0.2 &&
    contents.yellow.threshold != 0.2 &&
    contents.green.threshold != 0.2 &&
    contents.orange.threshold != 0.2
{
    taskComplete = true
}
else {
    taskComplete = false
}
if taskComplete {
    PlaygroundPage.current.assessmentStatus = .pass(message: NSLocalizedString("Great job!", comment: "Great job string"))
    
    let theArray = [PlaygroundValue.floatingPoint(contents.red.threshold),
                    PlaygroundValue.floatingPoint(contents.blue.threshold),
                    PlaygroundValue.floatingPoint(contents.yellow.threshold),
                    PlaygroundValue.floatingPoint(contents.green.threshold),
                    PlaygroundValue.floatingPoint(contents.orange.threshold)]
    PlaygroundKeyValueStore.current["thresholds"] = .array(theArray)
    PlaygroundKeyValueStore.current["testFloat"] = .floatingPoint(1.7)
}
else {
    PlaygroundPage.current.assessmentStatus = .fail(hints: [NSLocalizedString("For the best musical response, set the threshold as low as possible so that the Skoog responds as quickly as possible. Don't set it too low, though, or the Skoog might play with accidental touches.", comment: "Graph page hint 1 string"), NSLocalizedString("Try setting all threshold values less than 0.2 for red, blue, yellow, green, orange.", comment: "Graph page hint 2 string")], solution: nil)
}
