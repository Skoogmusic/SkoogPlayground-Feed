//#-hidden-code
//
//  Contents.swift
//
//  Copyright (c) 2017 Skoogmusic Ltd. All Rights Reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
**Goal** - Get more than one note per side by pressing hard or soft.

 The `press(side: Side, strength: Double)` [event handler](glossary://eventHandler) is great for counting press events, but it can also tell you lots of useful things about how the Skoog is being pressed.
 
 * callout(Useful `Side` [parameters](glossary://parameter)):
    * `value` - the raw `squeeze` value.
    * `name` - a `ColorString` used to identify the side `.red`, `.blue`, `.yellow`, `.green` or `.orange`.
    * `index` - a number used to identify the side - 0 to 4 for red, blue, yellow, green and orange.

**Challenge:** Adjust the values below to set a [threshold](glossary://threshold) that will let you play notes an [octave](glossary://octave) (12 [MIDI numbers](glossary://midiNumber)) higher than normal when you press hard.
*/
//#-hidden-code

import UIKit
import PlaygroundSupport
import CoreAudioKit
import SpriteKit
import SceneKit

PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

public class skoogContents: PlaygroundViewController {
//    public var inst: SoundStyle = .sineWave

    func setup() {
		playNotes = true
		releaseNotes = true
		showNoteLabels = true
    }
//#-end-hidden-code
//#-code-completion(everything, hide)
func press(side: Side, strength: Double) {
	let softNotes = [60,62,64,65,67]
	var myNote = softNotes[side.index]
    var threshold = /*#-editable-code */0.99/*#-end-editable-code*/
	
	if strength > threshold {
		myNote = myNote + /*#-editable-code */5/*#-end-editable-code*/
	}
	
	let mySide = side
	setNotes (side: mySide, note: myNote)
    //#-hidden-code

    printMessage((strength > threshold ? NSLocalizedString("Hard", comment: "Hard label") : NSLocalizedString("Soft", comment: "Soft label")),
                 value: String(format:"%0.2f", strength))
    checkTask(softNote:softNotes[side.index], myNote: myNote)
    //#-end-hidden-code
}
//#-hidden-code
	public override func peak(_ side: Side,_ peak: Double) {
		//on this page, call press before super, otherwise note settings will be out pf step
		press(side: side, strength: peak)
		super.peak(side, peak)
	}
    
    var taskCount = 0
    var taskComplete : Bool = false

    func checkTask(softNote: Int, myNote: Int){
        taskCount = taskCount + 1
        if (myNote - softNote == 12) && !taskComplete {
            PlaygroundPage.current.assessmentStatus = .pass(message: NSLocalizedString("Great job!", comment: "Great job string"))
            taskComplete = true
        }
        else {
            if taskCount%20 == 19 && !taskComplete {
                PlaygroundPage.current.assessmentStatus = .fail(hints: [NSLocalizedString("Have you set the threshold to a value between 0.0 and 1.0?", comment: "hard/soft note hint string 1"), NSLocalizedString("Did you know that 1 [octave](glossary://octave) = 12 [MIDI numbers](glossary://midiNumber)?", comment: "hard/soft note hint string 2")], solution: nil)
            }
        }
    }

    
}
let contents	=	skoogContents()
contents.setup()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", NSLocalizedString("A black Skoog Circle appears in the center of the Live View. This will change color depending on what side of the Skoog you press, and a matching colored ripple will expand and fade across the screen. Labels will display details of the note being played, and if your code detected a hard press or a soft press.", comment: "live view 8 label"), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient3)

PlaygroundPage.current.liveView = contents
