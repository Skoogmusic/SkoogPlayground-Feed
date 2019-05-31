//#-hidden-code
/*
 Copyright (C) 2017 Skoogmusic Ltd. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information.
 
 */
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
**Goal:** Create a basic event handler to play 5 notes.

Ok, let's start setting up your Skoog as a musical instrument. The first step is to create an [event handler](glossary://eventHandler) to make notes play when you press buttons. By default Skoog will play notes in a [scale](glossary://scale) of C-major. Later you'll learn how to assign your own notes.
 
   * callout(New concept - Event Handler):
 
       An event handler is a routine/function triggered by an action from an external source such as a user’s touch/tap or an input device (like a Skoog!).

 **Challenge:** We've set up the orange button for you. Do the same for the red, blue, green and yellow buttons and check that you can play 5 different notes.

 
 */
//#-hidden-code

import UIKit
import PlaygroundSupport
import CoreAudioKit
import SpriteKit
import SceneKit


PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

public class skoogContents: PlaygroundViewController {
    public var inst: SoundStyle = .marimba
    
    func setup() {
        red.active = false
        blue.active = false
        yellow.active = false
        green.active = false
        orange.active = false
        
        changeAlpha = false
        growCircle  = false
        showRipples = true
        showSqueezeLabel = true
        playNotes   = true
        changeColor = true
        
        
        setSound(.acid)
        
        setThresholds(  red:    0.01,
                        blue:   0.01,
                        yellow: 0.01,
                        green:  0.01,
                        orange: 0.01)
        
        skoog.red.active = false
        skoog.blue.active = false
        skoog.yellow.active = false
        skoog.green.active = false
        skoog.orange.active = false
    }
    
func press(side: Side, strength: Double) {
//#-end-hidden-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, ==, ., red, blue, yellow, green, orange, side, name, play(), ColorString)
//#-code-completion(keyword, show, if, let)
if side.name == .orange {
    side.play()
}
    
//#-editable-code tap to edit
//#-end-editable-code
//#-hidden-code
}

    public override func peak(_ side: Side,_ peak: Double) {
        press(side: side, strength: peak)
        super.peak(side, peak)
        checkTask(side: side)
    }
    
    var sideArray = [false, false, false, false ,false]
    var successArray = [false, false, false, false ,false]
    
    func checkTask(side: Side){
        sideArray[side.index] = true
        successArray[side.index] = side.active
        
        if !sideArray.contains(false) {
            if successArray.contains(false){
                PlaygroundPage.current.assessmentStatus = .fail(hints: [NSLocalizedString("Try an 'if-else-statement' using the 'side.name' to test for .red, .blue, .yellow, .green and .orange.", comment: "handling skoog hint 1 string")], solution: nil)
                sideArray = [false, false, false, false ,false] //reset messages so hint only flashes every time all 5 notes are pressed
            }
            else{
                PlaygroundPage.current.assessmentStatus = .pass(message: NSLocalizedString("Great job!", comment: "Great job string"))
            }
        }
    }
}
let contents	=	skoogContents()
contents.setup()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", NSLocalizedString("A black Skoog Circle appears in the center of the Live View. This will change color depending on what side of the Skoog you press.", comment: "live view 2 label"), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient2)

PlaygroundPage.current.liveView = contents

//#-end-hidden-code
