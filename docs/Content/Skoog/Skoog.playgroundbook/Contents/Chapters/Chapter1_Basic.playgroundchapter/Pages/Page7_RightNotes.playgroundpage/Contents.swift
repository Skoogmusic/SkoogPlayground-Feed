//#-hidden-code
/*
 Copyright (C) 2016 Skoogmusic Ltd. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information.
 */
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 **Goal:** Assign a different note to each Skoog button.
 
 You'll have noticed that different buttons produce different notes.
 
 To change notes, we use the `setNotes()` function to adjust the [MIDI Number](glossary://midiNumber) for each side.
 
  * callout(MIDI Numbers):
 
     MIDI numbers go from 0 to 127 for low to high [notes](glossary://note). Think of them as keys going from left to right on a *very long piano keyboard*! Not many sounds can play this full range, however.
 
 **Exercise:** Use the default settings to explore a range of high and low notes. Notice the color order of low to high notes on your Skoog.
 
 **Challenge:** Tune the Skoog to 60, 62, 64, 67, 69. Can you figure out how to play Jingle Bells?
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
        //Override default values
        showRipples = true
        showNoteLabels = true

        //Set Instrument
        setSound(.acid)
        
//#-end-hidden-code 
//#-code-completion(everything, hide)
setNotes(red:    /*#-editable-code tap to add a MIDI number*/24/*#-end-editable-code*/,
         blue:   /*#-editable-code tap to add a MIDI number*/36/*#-end-editable-code*/,
         yellow: /*#-editable-code tap to add a MIDI number*/60/*#-end-editable-code*/,
         green:  /*#-editable-code tap to add a MIDI number*/84/*#-end-editable-code*/,
         orange: /*#-editable-code tap to add a MIDI number*/108/*#-end-editable-code*/)
//#-hidden-code
        checkTask()
    }
    
    var taskComplete : Bool = false
    
    func checkTask(){
        if  self.notes[0] == 60 &&
            self.notes[1] == 62 &&
            self.notes[2] == 64 &&
            self.notes[3] == 67 &&
            self.notes[4] == 69 &&
            !taskComplete
        {
            PlaygroundPage.current.assessmentStatus = .pass(message: NSLocalizedString("Great job!", comment: "Great job string"))
            taskComplete = true
        }
    }

}
let contents	=	skoogContents()
contents.setup()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", NSLocalizedString("A black Skoog Circle appears in the center of the Live View. This will change color depending on what side of the Skoog you press, and a matching colored ripple will expand and fade across the screen. A label will display the MIDI number, note name and octave number, depending on the side of the Skoog device being pressed.", comment: "live view 7 label"), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient3)

PlaygroundPage.current.liveView = contents
//#-end-hidden-code
