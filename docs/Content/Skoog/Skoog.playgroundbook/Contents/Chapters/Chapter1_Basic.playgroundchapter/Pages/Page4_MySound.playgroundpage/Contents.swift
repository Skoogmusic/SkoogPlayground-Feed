//#-hidden-code
/*
 Copyright (C) 2016 Skoogmusic Ltd. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information.
*/
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
**Goal:** Learn how to change your sound style.

 Now that you know how to change the response, let's find out how to change your sound. To change sound style we use:
 
    setSound(SoundStyle)
 
 There are lots of styles to choose from. Here are a handful to get you started:
 
   * callout(Sound Styles):
      * `.acid`
      * `.candyBee`
      * `.nylonguitar`
 
 **Exercise:** Try out each of the sound styles by coding their names into the space below.
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
//#-end-hidden-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, acid, candyBee, fmModulator, sineWave, solarWind, gamelan, strat, rhodes, jharp, marimba, ocarina, minimogo, elecpiano, nylonguitar, vibraphone, afromallet, timpani, .)
setSound(/*#-editable-code */.acid/*#-end-editable-code*/)
//#-hidden-code
    }
}
let contents	=	skoogContents()
contents.setup()
contents.printSoundStyle()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", NSLocalizedString("A black Skoog Circle appears in the center of the Live View. This will change color depending on what side of the Skoog you press, and a matching colored ripple will expand and fade across the screen.", comment: "live view 4 label"), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient1)

PlaygroundPage.current.liveView = contents
