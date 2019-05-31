//#-hidden-code
/*
 Copyright (C) 2016 Skoogmusic Ltd. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information.
*/
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
**Goal:** Make a looping counter to cycle through your sound styles repeatedly.
 
 As you've seen, with every press the counter gets higher and higher. To listen to the sounds again, without re-running your code, we need to create a **looping counter**.

  * callout(Create a looping counter):
     
    For a counter inside an event handler/loop, first decide on the highest number you are likely to need. When the counter reaches this number, set the counter to zero. Next time you add to the counter, your code will run from the start.

**Challenge:** Write an `else-if` statement to reset the counter to zero, and check that your looping counter works!
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
//#-code-completion(identifier, show, acid, candyBee, fmModulator, sineWave, solarWind, gamelan, strat, rhodes, jharp, marimba, ocarina, minimogo, elecpiano, nylonguitar, vibraphone, afromallet, timpani, =, ==, !=, *, +, -, /, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, count, presses, {, }, else, setSound(style))
//#-code-completion(keyword, show, if, else, let, var)
var count = 0
let presses = /*#-editable-code */5/*#-end-editable-code*/
//#-hidden-code
	func setup() {
		showSqueezeLabel = false
		showRipples = true
//#-end-hidden-code
//#-hidden-code
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
    else if count == 3 * presses + 1 {
        setSound(/*#-editable-code */.vibraphone/*#-end-editable-code*/)
    }
    else if count == 4 * presses + 1{
        setSound(/*#-editable-code */.jharp/*#-end-editable-code*/)
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
    
    var taskComplete : Bool = false
    var taskCount = 0
    func checkTask(instrument: SoundStyle, count: Int, presses: Int){
        taskCount = taskCount + 1
        
        if count < taskCount && !taskComplete {
            PlaygroundPage.current.assessmentStatus = .pass(message: NSLocalizedString("Great job!", comment: "Great job string"))
            taskComplete = true
        }
        else {
            if count == 5 * presses + 1 && !taskComplete {
                PlaygroundPage.current.assessmentStatus = .fail(hints: [NSLocalizedString("Write an `else if{}` statement that checks when the number of presses has played the last sound style 5 times.", comment: "in the loop hint string 1"), NSLocalizedString("When count gets to the end, try setting `count = 0`.", comment: "in the loop hint string 2")], solution: nil)
            }
        }
    }
    
}
let contents	=	skoogContents()
contents.setup()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", NSLocalizedString("A black Skoog Circle appears in the center of the Live View. This will change color depending on what side of the Skoog you press, and a matching colored ripple will expand and fade across the screen. Labels will display a count of the number of presses and the currently selected sound style.", comment: "live view 6 label"), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient1)

PlaygroundPage.current.liveView = contents
