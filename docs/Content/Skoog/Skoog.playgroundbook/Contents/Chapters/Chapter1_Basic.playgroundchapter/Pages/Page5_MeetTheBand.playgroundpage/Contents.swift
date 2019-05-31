//#-hidden-code
/*
 Copyright (C) 2016 Skoogmusic Ltd. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information.
*/
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
**Goal:** Use a counter to change your sound style automatically.
 
 Let's create a **counter** to keep track of how many times you've pressed Skoog, and use it to call `setSound()` when it reaches a certain value.
 
  * callout(New Concept - Press Event Handler):
 
     Every time you press the Skoog, the `press()` event handler is called, telling you what side was pressed, and how hard.
 
 We've added a set of `if-else-statements` to our `press()` event handler below, with a few details left for you to complete.
 
 **Exercise:** Choose 3 [sound styles](glossary://soundStyles) to try, then set the number of presses needed to switch styles.  With every press, the counter gets higher, so keep pressing to make sure you get to listen to all of the sound styles!
 
 **Challenge** Add an `else-if` statement to the end to add one (or more!) sound style to the counter.*/
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
//#-code-completion(identifier, show, acid, candyBee, fmModulator, sineWave, solarWind, gamelan, strat, rhodes, jharp, marimba, ocarina, minimogo, elecpiano, nylonguitar, vibraphone, afromallet, timpani, ==, !=, *, +, -, /, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, count, presses, {, }, setSound(style:), else)
//#-code-completion(keyword, show, else, if, let, var)
var count = 0
let presses = /*#-editable-code */5/*#-end-editable-code*/
//#-hidden-code
	func setup() {
		showSqueezeLabel = false
		showRipples = true
    }
//#-end-hidden-code
func press(side: Side, strength: Double)
{
    count = count + 1
    if count == 1 {
     setSound(/*#-editable-code */.acid/*#-end-editable-code*/)
    }
    else if count == presses + 1 {
      setSound(/*#-editable-code */.elecpiano/*#-end-editable-code*/)
    }
    else if count == 2 * presses + 1 {
      setSound(/*#-editable-code */.gamelan/*#-end-editable-code*/)
    }
    //#-editable-code Enter your challenge code here.
    //#-end-editable-code
//#-hidden-code
    printMessage(NSLocalizedString("Count", comment: "count label"), value: "\(count)", style: .normal )
    self.announcementString.append(String(format: "%@ %d", NSLocalizedString("Count", comment: "count label"), count))
    printSoundStyle()
    checkTask(instrument: instrument.type, count: count, presses: presses)
//#-end-hidden-code
}
//#-hidden-code
	
    public override func peak(_ side: Side,_ peak: Double) {
        press(side: side, strength: peak)
        super.peak(side, peak)
    }
    
    var inst : SoundStyle = .marimba
    var instCount = 0
    var taskComplete : Bool = false

    func checkTask(instrument: SoundStyle, count: Int, presses: Int){
        if instrument != inst {
            instCount = instCount + 1
            inst = instrument
        }
        
        if instCount > 3 && !taskComplete {
            PlaygroundPage.current.assessmentStatus = .pass(message: NSLocalizedString("Great job!", comment: "Great job string"))
            taskComplete = true
        }
        else {
            if count == 3 * presses + 1 && !taskComplete {
                PlaygroundPage.current.assessmentStatus = .fail(hints: [NSLocalizedString("Try using an else-if statement to check for 3x the number of presses plus 1. ", comment: "meet the band hint string 1")], solution: nil)
            }
        }
    }
}
let contents	=	skoogContents()
contents.setup()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", NSLocalizedString("A black Skoog Circle appears in the center of the Live View. This will change color depending on what side of the Skoog you press, and a matching colored ripple will expand and fade across the screen. Labels will display a count of the number of presses and the currently selected sound style.", comment: "live view 5 label"), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient1)

PlaygroundPage.current.liveView = contents
