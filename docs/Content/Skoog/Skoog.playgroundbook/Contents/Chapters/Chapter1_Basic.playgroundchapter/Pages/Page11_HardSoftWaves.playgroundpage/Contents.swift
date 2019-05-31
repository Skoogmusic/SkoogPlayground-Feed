//#-hidden-code
//
//  Contents.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
**Goal** - Give your Hard Note, Soft Note some visual feedback.

You've already seen how [thresholds](glossary://threshold) can be used for various things such as for preventing low numbers from getting through and for distinguishing between hard and soft presses on your Skoog.
 
Let's build on that last idea to extend the 2-note per side behavior from 'Hard Note, Soft Note'.
 
Its always nice to have the UI give a distinctive visual response for different types of events. In our case, the two events are *Soft* and *Hard* notes.
 
 **Challenge**  Add Pulse and Ripple effects to the "Hard Note, Soft Note" code block below to complete our Skoog UI.
 */
//#-hidden-code

import UIKit

import PlaygroundSupport
import CoreAudioKit
import SpriteKit
import SceneKit

PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

public class skoogContents: PlaygroundViewController {
    func setup() {
        playNotes = true
        releaseNotes = true
    }
//#-end-hidden-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, ripple(color:size:), pulse(color:size:))
//#-code-completion(identifier, show, color, value, side, ., size, strength, true, false)
    //#-code-completion(identifier, show, *, /, +, -, ==, !=, =, ., if, else, {, }, (, ), 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
//#-code-completion(literal, show, boolean, if, else, color)
func press(side: Side, strength: Double) {
    let softNotes = [60,62,64,65,67]
    var myNote = softNotes[side.index]
    var threshold = /*#-editable-code */0.65/*#-end-editable-code*/
    
    if strength > threshold {
        myNote = myNote + /*#-editable-code */7/*#-end-editable-code*/
        //#-editable-code tap to edit
        //#-end-editable-code
    }
    else {
        //#-editable-code tap to edit
        //#-end-editable-code
    }
    
    let mySide = side
    setNotes (side: mySide, note: myNote)
    //#-hidden-code
    printMessage((strength > threshold ? NSLocalizedString("Hard", comment: "Hard label") : NSLocalizedString("Soft", comment: "Soft label")),
                 value: String(format:"%0.2f", strength),
                 side: side)
    checkTask()
    //#-end-hidden-code
}
//#-hidden-code
    
    var rippleCount = 0
    public override func ripple(color: UIColor? = nil, size: Double? = nil) {
        super.ripple(color:color, size: size)
        rippleCount = rippleCount + 1
        
    }
    var pulseCount = 0
    public override func pulse(color: UIColor? = nil, size: Double? = nil) {
        super.pulse(color:color, size: size)
        pulseCount = pulseCount + 1
    }
    
    
    public override func peak(_ side: Side,_ peak: Double) {
        //on this page, call press before super, otherwise note settings will be out pf step
        press(side: side, strength: peak)
        super.peak(side, peak)
    }
    
    
    var taskCount = 0
    var taskComplete : Bool = false
    func checkTask(){
        taskCount = taskCount + 1
        if (pulseCount > 5) && (rippleCount > 5) && !taskComplete {
            PlaygroundPage.current.assessmentStatus = .pass(message: NSLocalizedString("Great job!", comment: "Great job string"))
            taskComplete = true
        }
        else {
            if taskCount%20 == 19 && !taskComplete {
                PlaygroundPage.current.assessmentStatus = .fail(hints: [NSLocalizedString("Try adding `ripple(color: side.color, size: strength)` to the `if`, and `ripple(color: side.color, size: strength)` to the `else`", comment: "dynamic ripples hint string 1")], solution: nil)
            }
        }
    }

}
let contents	=	skoogContents()
contents.setup()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", NSLocalizedString("A black Skoog Circle appears in the center of the Live View. This will change color depending on what side of the Skoog you press and a matching colored ripple or pulse will animate depending on your code.", comment: "live view 11 label"), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient5)

PlaygroundPage.current.liveView = contents
