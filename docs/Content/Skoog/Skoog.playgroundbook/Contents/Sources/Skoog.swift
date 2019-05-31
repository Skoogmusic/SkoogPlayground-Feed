//
//  Skoog.swift
//  Skoog
//
//  Created by Keith Nagle on 10/06/2016.
//  Copyright © 2016 Skoogmusic Ltd. All rights reserved.
//

import CoreMIDI
// MARK: use UIKit for iOS apps
import UIKit
// MARK: use Cocoa  for macOS apps
// import Cocoa
import QuartzCore

public protocol SkoogDelegate: class {
    func peak(_ side: Side,_ peak: Double)
    func continuous(_ side: Side)
    func release(_ side: Side)
    func skoogConnectionStatus(_ connected: Bool)
    func updateProbe(_ packet: [Int])
    func showMagnetWarning()
}

public enum ColorString: String {
    case red
    case blue
    case yellow
    case green
    case orange
    case white
    var string: String {
        switch self {
        case .red:
            return "red"
        case .blue:
            return "blue"
        case .yellow:
            return "yellow"
        case .green:
            return "green"
        case .orange:
            return "orange"
        case .white:
            return "white"
        }
    }
}




/**
 Side Class - used to store info about the playing state of each side of the Skoog
 
 - active:  Indicates if the side is turned on or off.
 - isPlaying:  Used to monitor the current playing state of the side.
 - color: UIColor value of the side.
 - rawValue: The raw squeeze data.
 - response: Sets the response adjustment level (0 - 12).
 - value: The response curve adjusted squeeze value.
 - peak: Reports the strength of peaks detected in the squeeze data.
 - angle: Reports the 0-359 degree angle (where yellow is 0 or 360 degrees) for the current press.
 - name: String name of the current side.
 - blend_in_xy:
 - blend_out_xy:
 - play(): Function to set the active state of the side to true (turn on).
 - stop(): Function to set the active state of the side to false (turn off).
 */

public class Side: NSObject {
    public var active : Bool = true
    public var isPlaying : Bool = false
    // MARK: use UIColor for iOS apps
    public var color : UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    // MARK: use NSColor for macOS apps
    //public var color : NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    public var rawValue : Double = 0
    public var value : Double = 0
    public var peak : Peak? = Peak.init()
    public var peakValue : Double? = 0
    public var deltaT : Double? = 0
    public var index : Int = 0 // perhaps not needed but useful for identifying by index for now
    public var response : Double = 0.0
    public var angle : Double = 0.0
    public var name : ColorString = .white
    public var blend_in_xy : Double = 0.0
    public var blend_out_xy : Double = 0.0
    public var blend_in_z : Double = 0.0
    public var dx : Double = 0.0
    public var dy : Double = 0.0
    public var dr : Double = 0.0
    public var dz : Double = 0.0
    public var threshold : Double = 0.0
    public func play() {
        self.active = true
    }
    public func stop() {
        self.active = false
    }
    public override init() {
        super.init()
    }
}

// The "singleton" instance
public let SkoogInstance = Skoog()

let skoogNotificationKey = "com.skoogmusic.skoogNotificationKey"


public class Skoog: NSObject {
    
    public weak var delegate:SkoogDelegate?
    
    enum Zone: Int {
        case red_side = 0,      // 1
        blue_side,              // 2
        yellow_side,            // 3
        green_side,             // 4
        orange_side,            // 5
        red_blue,               // 6
        blue_yellow,            // 7
        yellow_green,           // 8
        red_green,              // 9
        orange_red,             // 10
        orange_red_blue,        // 11
        orange_blue,            // 12
        orange_blue_yellow,     // 13
        orange_yellow,          // 14
        orange_yellow_green,    // 15
        orange_green,           // 16
        orange_red_green,       // 17
        none
    }
    var themidipacket : [Int] = [0, 0, 0, 0, 0, 0, 0]
    
    let bufferSize = 5
    
    var x1Buffer = Array(repeating: 0, count: 5)
    var y1Buffer = Array(repeating: 0, count: 5)
    var z1Buffer = Array(repeating: 0, count: 5)
    
    var x2Buffer = Array(repeating: 0, count: 5)
    var y2Buffer = Array(repeating: 0, count: 5)
    var z2Buffer = Array(repeating: 0, count: 5)
    
    var z3Buffer = Array(repeating: 0.0, count: 5) // added to try smooth out orange
    
    var magFieldStrengthBuffer = Array(repeating: 0, count: 5)
    
    var r1Buffer = Array(repeating: 0, count: 5)
    var r2Buffer = Array(repeating: 0, count: 5)
    
    var x1sum = 0.0
    var x2sum = 0.0
    var y1sum = 0.0
    var y2sum = 0.0
    var z1sum = 0.0
    var z2sum = 0.0

    var activeZones : [[Zone]] = [[.red_side, .none, .none],
                                  [.blue_side, .none, .none],
                                  [.yellow_side, .none, .none],
                                  [.green_side, .none, .none],
                                  [.orange_side, .none, .none],
                                  [.red_side, .blue_side, .none],
                                  [.blue_side, .yellow_side, .none],
                                  [.yellow_side, .green_side, .none],
                                  [.red_side, .green_side, .none],
                                  [.orange_side, .red_side, .none],
                                  [.orange_side, .red_side, .blue_side],
                                  [.orange_side, .blue_side, .none],
                                  [.orange_side, .blue_side, .yellow_side],
                                  [.orange_side, .yellow_side, .none],
                                  [.orange_side, .yellow_side, .green_side],
                                  [.orange_side, .green_side, .none],
                                  [.orange_side, .red_side, .green_side],
                                  [.none, .none, .none]];
    
    public class var sharedInstance:Skoog {
        return SkoogInstance
    }
    
    var status = OSStatus(noErr)
    var midiClient = MIDIClientRef()
    var outputPort = MIDIPortRef()
    var inputPort = MIDIPortRef()
    var virtualSourceEndpointRef = MIDIEndpointRef()
    var virtualDestinationEndpointRef = MIDIEndpointRef()
    var midiInputPortref = MIDIPortRef()
    
    public var red : Side
    public var blue : Side
    public var yellow : Side
    public var green : Side
    public var orange : Side
    public var sides : [Side]
    
    public var polyMode = true
    public var sendVirtualMIDI = false // set to true for BLE macOS
    public var sendNetworkMIDI = false
    public var threshRelease : Bool = true
    
    var R1 : Double = 0.0
    var R2 : Double = 0.0
    var T1 : Double = 0.0
    var T2 : Double = 0.0
    var Z3 : Double = 0.0
    var ZC : Double = 0.0
    var DX : Double = 0.0
    var DY : Double = 0.0
    var Rxy : Double = 0.0
    var Rxyz : Double = 0.0
    public var Txy : Double = 0.0
    var dT : Double = 0.0
    var Tz : Double = 0.0
    public var R_zoom : Double = 0.0
    public var Z_zoom : Double = 0.0
    
    var Rxyz_old : Double = 0.0;
    var Rxy_old : Double = 0.0;
    var R1_old : Double = 0.0;
    var R2_old : Double = 0.0;
    var T1_old : Double = 0.0;
    var T2_old : Double = 0.0;
    var Tz_old : Double = 0.0;
    var Z3_old : Double = 0.0;
    
    var lastZone : Zone = .none
    var zone : Zone = .none
    var param2 : Double = 0
    var param3 : Double = 0
    var param4 : Double = 0
    
    public var threshold : Double = 0
    public var z_threshold : Double = 0
    public var thresholdZoom : Double = 0
    public var z_thresholdZoom : Double = 0
    var XYcone : Double = 15.0
    var ZconeZ : Double = 11.5
    var ZconeXY : Double = 22.5
    var coneAngle : Double = 0
    var redBlueAngle : Double = 0
    var blueYellowAngle : Double = 0
    var yellowGreenAngle : Double = 0
    var redGreenAngle : Double = 0
    var bend_note : Double = 0
    var bend_out : Double = 0
    var bend_in : Double = 0
    var blend_out_xy : Double = 0
    var blend_in_xy : Double = 0
    var blend_out_z : Double = 0
    var blend_in_z : Double = 0
    
    var Tz_corrected : Double = 0
    var Z3_corrected : Double = 0
    var blocking = false
    public var calibrating = false
    public var skoogConnected = false
    public var midiInputPortConnectionMade = false
    var currenttime = NSDate()
    var lasttime = NSDate()
    
    var firmwareMajorVersion : Int = -1
    var firmwareMinorVersion : Int = -1
    
    var lastPacket : Double = 0.0
    var currentPacket : Double = 0.0
    var lastTime : Double = 0.0
    var currentTime : Double = 0.0
    var packetCount : Int = 0
    var canShowWarning = false
    var magnetThreshold : Int = 68
    
    override init() {
        self.red = Side()
        self.blue = Side()
        self.yellow = Side()
        self.green = Side()
        self.orange = Side()
        
        self.red.index = 0
        self.blue.index = 1
        self.yellow.index = 2
        self.green.index = 3
        self.orange.index = 4
        
        self.red.name = .red //"red"
        self.blue.name =  .blue //"blue"
        self.yellow.name = .yellow //"yellow"
        self.green.name = .green //"green"
        self.orange.name = .orange //"orange"
        
        self.sides = [red, blue, yellow, green, orange]
        
        // MARK: Use UIColor for iOS apps
        self.red.color      =   UIColor(red: 218.0/255.0, green: 60.0/255.0, blue: 0.0, alpha: 1.0)
        self.blue.color     =   UIColor(red: 55.0/255.0, green: 127.0/255.0, blue: 178.0/255.0, alpha: 1.0)
        self.yellow.color   =   UIColor(red: 254.0/255.0, green: 224.0/255.0, blue: 0.0, alpha: 1.0)
        self.green.color    =   UIColor(red: 61.0/255.0,  green: 155.0/255.0, blue: 53.0/255.0, alpha: 1.0)
        self.orange.color   =   UIColor(red: 249.0/255.0, green: 154.0/255.0, blue: 0.0, alpha: 1.0)
        
        // MARK: Use NSColor for macOS apps
        /*
		self.red.color      =   NSColor(red: 218.0/255.0, green: 60.0/255.0, blue: 0.0, alpha: 1.0)
        self.blue.color     =   NSColor(red: 55.0/255.0, green: 127.0/255.0, blue: 178.0/255.0, alpha: 1.0)
        self.yellow.color   =   NSColor(red: 254.0/255.0, green: 224.0/255.0, blue: 0.0, alpha: 1.0)
        self.green.color    =   NSColor(red: 61.0/255.0,  green: 155.0/255.0, blue: 53.0/255.0, alpha: 1.0)
        self.orange.color   =   NSColor(red: 249.0/255.0, green: 154.0/255.0, blue: 0.0, alpha: 1.0)*/
        
        super.init()
        
        self.R1 = 0
        self.T1 = 180
        self.R2 = 0
        self.T2 = 180
        self.Z3 = 0
        self.DX = 64
        self.DY = 64
        self.Rxy = 0
        self.Rxyz = 0
        self.Txy = 180
        self.dT = 0
        self.Tz = 90
        self.threshold = 0.0014 // was 0.02
        self.z_threshold = 0.0014
        self.thresholdZoom = 0.0014
        self.z_thresholdZoom = 0.0014 // 0.018
        self.R_zoom = 1.0
        self.Z_zoom = 1.0
        
        self.XYcone = 16 //these values "fill" the space - temporary until cone of shame implememted
        self.ZconeZ = 16.5
        self.ZconeXY = 10.0
        self.zone = .none
        self.lastZone = .none
        self.param3 = 0.0
        self.param4 = 0.0
        
        setPolyMode(active:self.polyMode)
        //        changeXYcone(XYcone)
        //        searchForSkoog()
        
        status = MIDIClientCreateWithBlock("com.skoogmusic.myMIDIClient" as CFString, &midiClient, MyMIDINotifyBlock)
        if status != noErr {
            print("Error creating midi client : \(status)")
        }
        else{
//            print("Created midi client : \(status)")
        }
        
        status = MIDISourceCreate(midiClient,
                                  "Skoog" as CFString,
                                  &virtualSourceEndpointRef)
        if status == noErr {
//            print("created virtual destination")
        } else {
            print("error creating virtual destination: \(status)")
        }
    }
    // MARK: MIDI methods
    func MyMIDINotifyBlock(midiNotification: UnsafePointer<MIDINotification>) {
        let notification = midiNotification.pointee
        switch (notification.messageID) {
        case .msgSetupChanged:
//            print("Setup changed!")
//            searchForSkoog()
			break
        case .msgObjectAdded:
            print("Object added!")
            if !skoogConnected {
                //print("Object added! - Searching for skoog")
                searchForSkoog()
            }
        case .msgObjectRemoved:
            //print("Object removed!")
            if skoogConnected {
                searchForSkoog()
            }
        case .msgPropertyChanged:
//            print("Property changed!")
            print("")
        case .msgThruConnectionsChanged:
            print("Thru connections changed!")
        case .msgSerialPortOwnerChanged:
            print("Serial port owner changed!")
        case .msgIOError:
            print("IO Error!")
        }
    }
    
    //The system assigns unique IDs to all objects
    func getUniqueID(_ endpoint:MIDIEndpointRef) -> (OSStatus, MIDIUniqueID) {
        var id = MIDIUniqueID(0)
        let status = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &id)
        if status != noErr {
            print("error getting unique id \(status)")
            //checkError(status)
        }
        return (status,id)
    }
    
    public func notify(notification:Notification) -> Void {
        //        //respond to status update notifications
        //        print("Catch notification")
        //
        //        guard let userInfo = notification.userInfo,
        //            let connectionStatus  = userInfo["connectionStatus"] as? Bool else {
        //                print("No userInfo found in notification")
        //                return
        //        }
        //        let alert = UIAlertController(title: "Notification!",
        //                                      connectionStatus:"\(connectionStatus) received",
        //            preferredStyle: UIAlertControllerStyle.alert)
        //        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        //        self.present(alert, animated: true, completion: nil)
    }
    
    public func searchForSkoog() {
        print("SEARCH FOR SKOOG CALLED")
        let numberOfDevices = MIDIGetNumberOfDevices()
        
        for count:Int in 0 ..< numberOfDevices {
            let midiDevice = MIDIGetDevice(count)
            var unmanagedProperties: Unmanaged<CFPropertyList>?
            
            MIDIObjectGetProperties(midiDevice, &unmanagedProperties, false)
            if let midiProperties: CFPropertyList = unmanagedProperties?.takeUnretainedValue() {
                let midiDictionary = midiProperties as! NSDictionary
                if (midiDictionary.object(forKey: "name") as! String == "Skoog" && midiDictionary.object(forKey: "offline") as! Int == 0) {
                    //print("Found a connected Skoog! \(midiDictionary.object(forKey: "uniqueID"))")
                    skoogConnected = true
                    if skoogConnected == true {
                        delegate?.skoogConnectionStatus(true)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: skoogNotificationKey), object: nil, userInfo: ["connectionStatus": self.skoogConnected])                    }
                    // reset firmware version. Will start accepting signals once we discover the real firmware version
                    firmwareMajorVersion = -1
                    firmwareMinorVersion = -1
                    // start accepting MIDI packets from Skoog
                    if !midiInputPortConnectionMade {
                        start()
                    }
                    break
                }
                else if (midiDictionary.object(forKey: "name") as! String == "Skoog" && midiDictionary.object(forKey: "offline") as! Int == 1){
                    //print("Found an offline Skoog!")
                    skoogConnected = false
                    //                    print("set skoogConnected = false 4")
                }
                
            }
            else {
                print("Unable to load properties for \(count)")
            }
        }
        // if we get this far, there are no connected skoogs
        if skoogConnected == false {
            delegate?.skoogConnectionStatus(false)
            NotificationCenter.default.post(name: Notification.Name(rawValue: skoogNotificationKey), object: nil, userInfo: ["connectionStatus": self.skoogConnected])
            midiInputPortConnectionMade = false
        }
    }
    
    func connectSourcesToInputPort() {
        var status = OSStatus(noErr)
        let sourceCount = MIDIGetNumberOfSources()
        print("source count \(sourceCount)")
        
        for srcIndex in 0 ..< sourceCount {
            let midiEndPoint = MIDIGetSource(srcIndex)
            status = MIDIPortConnectSource(inputPort,
                                           midiEndPoint,
                                           nil)
            if status == OSStatus(noErr) {
                print("yay connected endpoint to inputPort!")
                midiInputPortConnectionMade = true
            } else {
                print("Oh, no!")
            }
            status = MIDIPortConnectSource(inputPort, MIDINetworkSession.default().sourceEndpoint(), nil)
        }
    }
    
    public func sendMidiNoteOn(note: Int, velocity: Int, channel: Int) {
        
        var packet:MIDIPacket = MIDIPacket();
        packet.timeStamp = 0;
        packet.length = 3;
        packet.data.0 = 0x90 + UInt8(channel); // Note On event channel 1
        packet.data.1 = UInt8(note) //0x3C; // Note C3
        packet.data.2 = UInt8(velocity); // Velocity
        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet);
        
        if sendNetworkMIDI {
            // Get the first destination
            let dest:MIDIEndpointRef = MIDIGetDestination(0);
            MIDISend(outputPort, dest, &packetList);
        }
        
        if sendVirtualMIDI {
            MIDIReceived(virtualSourceEndpointRef, &packetList)
        }
    }
    
    public func sendMidiNoteOff(note: Int, velocity: Int, channel: Int) {
        var packet:MIDIPacket = MIDIPacket();
        packet.timeStamp = 0;
        packet.length = 3;
        packet.data.0 = 0x80 + UInt8(channel); // Note Off event channel 1
        packet.data.1 = UInt8(note) //0x3C; // Note C3
        packet.data.2 = UInt8(velocity); // Velocity
        var packetList = MIDIPacketList(numPackets: 1, packet: packet);
        
        if sendNetworkMIDI {
            // Get the first destination
            let dest:MIDIEndpointRef = MIDIGetDestination(0);
            MIDISend(outputPort, dest, &packetList);
        }
        if sendVirtualMIDI {
            MIDIReceived(virtualSourceEndpointRef, &packetList)
        }
    }
    
    public func sendMidiContinuous(note: Int, velocity: Int, channel: Int) {
        var packet:MIDIPacket = MIDIPacket();
        packet.timeStamp = 0;
        packet.length = 3;
        packet.data.0 = 0xA0 + UInt8(channel); // Note Off event channel 1
        packet.data.1 = UInt8(note) //0x3C; // Note C3
        packet.data.2 = UInt8(velocity); // Velocity
        var packetList = MIDIPacketList(numPackets: 1, packet: packet);
        
        if sendNetworkMIDI {
            // Get the first destination
            let dest:MIDIEndpointRef = MIDIGetDestination(0);
            MIDISend(outputPort, dest, &packetList);
        }
        if sendVirtualMIDI {
            MIDIReceived(virtualSourceEndpointRef, &packetList)
        }
    }
    
    public func start(){
        var readBlock: MIDIReadBlock
        readBlock = MyMIDIReadBlock
        
        var status = OSStatus(noErr)
        
        if status == OSStatus(noErr) {
            status = MIDIPortDispose(inputPort)
            if status == OSStatus(noErr) {
                print("disposed of input port")
            } else {
                print("error disposing of input port : \(status)")
            }
            status = MIDIPortDispose(outputPort)
            if status == OSStatus(noErr) {
                print("disposed of output port")
            } else {
                print("error disposing of output port : \(status)")
            }
        }
        
        status = OSStatus(noErr)
        
        if status == OSStatus(noErr) {
            status = MIDIInputPortCreateWithBlock(midiClient, "com.skoogmusic.MIDIInputPort" as CFString, &inputPort, readBlock)
            if status == OSStatus(noErr) {
                print("created input port")
            } else {
                print("error creating input port : \(status)")
            }
        }
        status = MIDIOutputPortCreate(midiClient,
                                      "com.skoogmusic.OutputPort" as CFString,
                                      &outputPort)
        
        if status == noErr {
            print("created output port")
        } else {
            print("error creating output port : \(status)")
        }
        
        //        status = MIDIDestinationCreateWithBlock(midiClient,
        //                                                "com.skoogmusic.VirtualDest" as CFString,
        //                                                &virtualDestinationEndpointRef,
        //                                                MIDIPassThru)
        enableNetwork()
        connectSourcesToInputPort()
        
    }
    
    ///  Take the packets emitted frome the MusicSequence and forward them to the virtual source.
    ///
    ///  - parameter packetList:    packets from the MusicSequence
    ///  - parameter srcConnRefCon: not used
    func MIDIPassThru(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) -> Swift.Void {
        print("sending packets to source \(packetList)")
        MIDIReceived(virtualSourceEndpointRef, packetList)
        
        //        dumpPacketList(packetList.memory)
    }
    
    func enableNetwork() {
        MIDINetworkSession.default().isEnabled = true
        MIDINetworkSession.default().connectionPolicy = .anyone
        print("net session enabled \(MIDINetworkSession.default().isEnabled)")
        print("net session networkPort \(MIDINetworkSession.default().networkPort)")
        print("net session networkName \(MIDINetworkSession.default().networkName)")
        print("net session localName \(MIDINetworkSession.default().localName)")
        
    }
    
    func MyMIDIReadBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) -> Swift.Void {
        let packets = packetList.pointee
        let packet:MIDIPacket = packets.packet
        var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        ap.initialize(to:packet)
        
        for _ in 0 ..< packets.numPackets {
            let p = ap.pointee
            handle(p)
            ap = MIDIPacketNext(ap)
        }
    }
    
    func medianFilter(array: [Int]) ->[Int] {
        var output : [Int] = array
        for i in 0...bufferSize-2 {
            if i == 0 {
                let replacementArray = [array[0], array[0], array[1]]
                output[i] = replacementArray.sorted()[1]
            }
            else {
                let replacementArray = [array[i-1], array[i], array[i+1]]
                output[i] = replacementArray.sorted()[1]
            }
        }
        return output
    }
    
    func medianFilter(array: [Double]) ->[Double] {
        var output : [Double] = array
        for i in 0...bufferSize-2 {
            if i == 0 {
                let replacementArray = [array[0], array[0], array[1]]
                output[i] = replacementArray.sorted()[1]
            }
            else {
                let replacementArray = [array[i-1], array[i], array[i+1]]
                output[i] = replacementArray.sorted()[1]
            }
        }
        return output
    }
    // MARK: PREPROCESS
    func preprocess(_ packet:MIDIPacket) {
        // small bit of pre-processing to get numbers
        // from the MIDI range into a more sensible range for dealing with angles
        
        // if we're the new firmware version
        if firmwareMajorVersion == 0 && firmwareMinorVersion == 0 { // old firmware version (indiegogo and first Apple revision (no firmware number on either)
            R1 = Double(packet.data.2) / 127.0
            T1 = Double(packet.data.5) * (360.0 / 127.0)
            R2 = Double(packet.data.8) / 127.0
            T2 = Double(packet.data.11) * (360.0 / 127.0)
            Z3 = Double(packet.data.14) / 127.0
            // this may end up being a different method or variation of decodeAngle()
            decodeAngle()
            // routeSignals might always be the same function, but if the firmware version is -1 then we don't to send anything yet
            // Maybe need something cleverer that this
            // MARK: Use routeMono() in Playgrounds, Bluetooth MIDI and Skratch.
            routeMono()
            // MARK: Use routeSignals() for Skoog iOS
            // routeSignals()
        }
        else if firmwareMajorVersion > 0 && firmwareMinorVersion > 0 {
            var x1 = Double(Int8(truncatingIfNeeded: Int(packet.data.2)))
            var y1 = Double(Int8(truncatingIfNeeded: Int(packet.data.5)))
            var z1 = Double(Int8(truncatingIfNeeded: Int(packet.data.8)))
            var x2 = Double(Int8(truncatingIfNeeded: Int(packet.data.11)))
            var y2 = Double(Int8(truncatingIfNeeded: Int(packet.data.14)))
            var z2 = Double(Int8(truncatingIfNeeded: Int(packet.data.17)))
            
            x1Buffer.remove(at: bufferSize - 1)
            x1Buffer.insert(Int(x1), at: 0)
            
            y1Buffer.remove(at: bufferSize - 1)
            y1Buffer.insert(Int(y1), at: 0)
            
            z1Buffer.remove(at: bufferSize - 1)
            z1Buffer.insert(Int(z1), at: 0)
            
            x2Buffer.remove(at: bufferSize - 1)
            x2Buffer.insert(Int(x2), at: 0)
            
            y2Buffer.remove(at: bufferSize - 1)
            y2Buffer.insert(Int(y2), at: 0)
            
            z2Buffer.remove(at: bufferSize - 1)
            z2Buffer.insert(Int(z2), at: 0)
            
            let zcorr = xcorrelate_bignorm(array1: z1Buffer, array2: z2Buffer)
            
            let magFieldStrength = Double(Int8(truncatingIfNeeded: Int(packet.data.20)))
            
            if x1 == magFieldStrength && (y1 == 0 && z1 == 0 && x2 == 0 && y2 == 0 && z2 == 0){
                //print("Filtering a glitch!!!!!!!!!!!!!!!!")
                x1 = 0
            }
            
            if x1 == magFieldStrength {
                x1Buffer[0] = medianFilter(array: x1Buffer)[1]
            }
            if y1 == x1 && y1 != 0 {
                y1Buffer[0] = medianFilter(array: y1Buffer)[1]
            }
            if z1 == y1 && z1 != 0  {
                z1Buffer[0] = medianFilter(array: z1Buffer)[1]
            }
            if x2 == z1 && x2 != 0  {
                x2Buffer[0] = medianFilter(array: x2Buffer)[1]
            }
            if y2 == x2 && y2 != 0  {
                y2Buffer[0] = medianFilter(array: y2Buffer)[1]
            }
            if z2 == y2 && z2 != 0 {
                z2Buffer[0] = medianFilter(array: z2Buffer)[1]
            }
            
            let r1 = getMagnitude(Double(x1Buffer[0]), y: Double(y1Buffer[0]))
            r1Buffer.remove(at: bufferSize - 1)
            r1Buffer.insert(Int(r1), at: 0)
            let r2 = getMagnitude(Double(x2Buffer[0]), y: Double(y2Buffer[0]))
            r2Buffer.remove(at: bufferSize - 1)
            r2Buffer.insert(Int(r2), at: 0)
            
            // get values in the range of -1.0 to +1.0
            x1 = x1Buffer[0] < 0 ? Double(x1Buffer[0]) / 128.0 : Double(x1Buffer[0]) / 127.0
            y1 = y1Buffer[0] < 0 ? Double(y1Buffer[0]) / 128.0 : Double(y1Buffer[0]) / 127.0
            z1 = z1Buffer[0] < 0 ? Double(z1Buffer[0]) / 128.0 : Double(z1Buffer[0]) / 127.0
            
            x2 = x2Buffer[0] < 0 ? Double(x2Buffer[0]) / 128.0 : Double(x2Buffer[0]) / 127.0
            y2 = y2Buffer[0] < 0 ? Double(y2Buffer[0]) / 128.0 : Double(y2Buffer[0]) / 127.0
            z2 = z2Buffer[0] < 0 ? Double(z2Buffer[0]) / 128.0 : Double(z2Buffer[0]) / 127.0
            
            // get the average x and y. z is 0.0 for now
            var x = 0.5 * (x1 + x2)
            var y = 0.5 * (y1 + y2)
            var z = 0.0
            
            let x1_0 = x1Buffer[2] < 0 ? Double(x1Buffer[2]) / 128.0 : Double(x1Buffer[2]) / 127.0
            let dx1 = x1 - x1_0
            
            let x2_0 = x2Buffer[2] < 0 ? Double(x2Buffer[2]) / 128.0 : Double(x2Buffer[2]) / 127.0
            let dx2 = x2 - x2_0
            
            let y1_0 = y1Buffer[2] < 0 ? Double(y1Buffer[2]) / 128.0 : Double(y1Buffer[2]) / 127.0
            let dy1 = y1 - y1_0
            
            let y2_0 = y2Buffer[2] < 0 ? Double(y2Buffer[2]) / 128.0 : Double(y2Buffer[2]) / 127.0
            let dy2 = y2 - y2_0
            
            let z1_0 = z1Buffer[2] < 0 ? Double(z1Buffer[2]) / 128.0 : Double(z1Buffer[2]) / 127.0
            let dz1 = z1 - z1_0
            
            let z2_0 = z2Buffer[2] < 0 ? Double(z2Buffer[2]) / 128.0 : Double(z2Buffer[2]) / 127.0
            let dz2 = z2 - z2_0
            
            let z1r1corr = xcorrelate_bignorm(array1: z1Buffer, array2: r1Buffer)
            let z1r2corr = xcorrelate_Znorm(Zarray1: z1Buffer, array2: r2Buffer)
            
            let z2r2corr = xcorrelate_bignorm(array1: z2Buffer, array2: r2Buffer)
            let z2r1corr = xcorrelate_Znorm(Zarray1: z2Buffer, array2: r1Buffer)
            
            var zcorrgate = 0.0
            
            // essentially the average of r1 r2, but calculated with magnitude
            let r = getMagnitude(x, y: y)
            
            // how far do r1 and r2 deviate from the average
            let dev_r1 = (r1 - r)*(r1 - r)
            let dev_r2 = (r2 - r)*(r2 - r)
            // average that to get the variance
            let rvariance = 0.5 * (dev_r1 + dev_r2)
            // deviation
            let rdev = !r.isZero ? sqrt(rvariance)/r : 0
            
            // average z1 z2
            let _z_ = 0.5 * (z1 + z2)
            // how far do z1 z2 deviate from average
            let dev_z1 = (z1 - _z_)*(z1 - _z_)
            let dev_z2 = (z2 - _z_)*(z2 - _z_)
            // average that to get the variance
            let zvariance = 0.5 * (dev_z1 + dev_z2)
            // deviation
            let zdev = !_z_.isZero ? sqrt(zvariance)/abs(_z_) : 0
            
            // MARK: Comment out for Swift Playgrounds
//            if zcorr.isFinite && z1r1corr.isFinite && z2r2corr.isFinite && z2r1corr.isFinite && z1r2corr.isFinite {
//                if !zcorr.isZero && (!z1r1corr.isZero || !z2r1corr.isZero || !z2r2corr.isZero || !z1r2corr.isZero) {
//                    zcorrgate = zcorr / (abs(z1r1corr) + abs(z2r1corr) + abs(z2r2corr) + abs(z1r2corr))
//                }
//                else {
//                    if zcorr > 0.00003 { //was 0.00003
//                        zcorrgate = 100 //zcorr
//                    }
//                }
//            }
            
            //setup debug messages
            var message = ""
            if firmwareMajorVersion == 2 && firmwareMinorVersion == 1 {
                if self.polyMode == false { // Mono mode. Always true for playgrounds, Skratch and Bluetooth MIDI. Optional for Skoog iOS app
                    let rz1corr = xcorrelate_bignorm(array1: z1Buffer, array2: r1Buffer)
                    let rz2corr = xcorrelate_bignorm(array1: z2Buffer, array2: r2Buffer)
                    if zcorr.isFinite && rz1corr.isFinite && rz2corr.isFinite {
                        if (!rz1corr.isZero || !rz2corr.isZero) {
                            zcorrgate = zcorr / (rz1corr + rz2corr)
                        }
                        else if zcorr > 0.2 {
                            zcorrgate = 100//zcorr
                        }
                    }
                    
                    if zcorrgate > 0.3 {
                        z = 0.5 * Double(z1Buffer[1] + z2Buffer[1]) / 127.0
                    }
                }
                else { // Poly mode true. Currently only possible in Skoog iOS
                    if !x1.isZero && !x2.isZero {
                        z = z2
                        if zdev < 1 {
                            zcorrgate = zdev < 0.5 ? z * (1-zdev) * zcorrgate : z * zcorrgate / (1-zdev)
                        }
                        else if zdev > 1 {
                            zcorrgate = z * zcorrgate * zdev
                        }
                        else{
                            zcorrgate = z * zcorrgate
                        }
                        if x1 > 0 && x2 > 0 { //BLUE & REDBLUE & YELLOWBLUE
                            if zcorrgate > 0.05 {
                                print("PASS1>    zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.2f",  z))")
                            }
                            else{
                                z = 0
                                print("BLOCK>    zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.2f",  z))")
                            }
                        }
                        else if x1 < 0 && x2 < 0 && y1 < 0 && y2 < 0 { //YELLOWGREEN
                            if z > 0.01 {
                                print("PASS3>    zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.8f",  z))")
                            }
                            else{
                                print("BLOC3>    zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.8f",  z))")
                                z = 0
                            }
                        }
                        else {
                            zcorrgate = zcorrgate * (6.0 * rdev + 0.15)
                            z = z * ((zcorrgate + 0.2 ) )
                            if z > 0.0001 {
                                
                                print("PASS2>    zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.8f",  z))")
                            }
                            else{
                                z = 0
                                print("BLOC2>    zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.8f",  z))")
                            }
                        }
                    }
                    else if !y1.isZero && !y2.isZero {
                        z = z1
                        if zdev < 1 {
                            zcorrgate = zdev < 0.5 ? z * (1-zdev) * zcorrgate : z * zcorrgate / (1-zdev)
                        }
                        else{
                            zcorrgate = zcorr
                        }
                        if y1 > 0 && y2 > 0 {
                            if zcorrgate > 0.001 {
                                print("PASS1>>   zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.2f",  z))")
                            }
                            else{
                                z = 0
                                print("BLOCK>>   zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.2f",  z))")
                            }
                        }
                        else if y1 < 0 && y2 < 0 && x2 > 0 { //YELLOWBLUE
                            z = z2
                            if zcorrgate < 0.001 {
                                z = 0
                            }
                        }
                        else {
                            if zcorrgate > 0.001 {
                                print("PASS2>>   zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.2f",  z)) ")
                            }
                            else{
                                z = 0
                                print("BLOCK>>   zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : zdev \(String(format: "%.2f",  zdev)) : z \(String(format: "%.2f",  z)) ")
                            }
                        }
                    }
                    else {
                        z = 0.5 * (z1 + z2)
                        if zcorrgate != 100 {
                            if zdev > 0 && zdev < 1 {
                                zcorrgate = zdev < 0.5 ? z * z * (1-zdev) * zcorr : z * z * zcorr / (1-zdev)
                            }
                            else if zdev == 0 {
                                zcorrgate = z * z * zcorr
                            }
                            else {
                                zcorrgate = zcorr
                            }
                        }
                        if abs(zcorrgate) > 0.00002 {
                            print("PASS >>>  zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : z = \(String(format: "%.8f",  z)) : zdev = \(String(format: "%.8f",  zdev))")
                        }
                        else {
                            z = 0
                            print("BLOCK>>>  zcorr: \(String(format: "%.4f",  zcorr)) : zcorrgate = \(String(format: "%.8f",  zcorrgate)) : z = \(String(format: "%.8f",  z)) : zdev = \(String(format: "%.8f",  zdev))")
                        }
                    }
                    if x1 > 0 && x2 > 0 && y1 > 0 && y2 > 0 {
                        zcorrgate = -zcorrgate * (0.25 * rdev - 2)
                        z = z * ((zcorrgate / 0.6) - 0.4)
                        
                        if (z > 0.01) {
                            print("PASS >>>> zcorr: \(String(format: "%.2f",  zcorr)) : zcorrgate = \(String(format: "%.4f",  zcorrgate)) : z = \(String(format: "%.4f",  z)) : zdev = \(String(format: "%.4f",  zdev)) : 1 - zdev/rdev = \(String(format: "%.4f",  1 - zdev/rdev))")
                        }
                        else {
                            z = 0
                            print("BLOCK>>>> zcorr: \(String(format: "%.2f",  zcorr)) : zcorrgate = \(String(format: "%.4f",  zcorrgate)) : z = \(String(format: "%.4f",  z)) : zdev = \(String(format: "%.4f",  zdev)) : 1 - zdev/rdev = \(String(format: "%.4f",  1 - zdev/rdev))")
                        }
                    }
                }
                getRadiusAndAngle(x, y, z)
                // once we've set our main variables the main
                // work can be done on decoding the signal
                decodeAngle2()
                // Then we can route the signals to any delegate listening for updates
                // MARK: use routeMono() for Playgrounds, Skratch and Bluetooth MIDI
                routeMono()
                // MARK: use routeSignals2() for Skoog iOS
//                routeSignals2()
            }
            else if firmwareMajorVersion >= 2 && firmwareMinorVersion >= 2 {
                // BOTH SENSORS NON-ZERO ON X
                if !x1.isZero && !x2.isZero {
                    if x1 > 0 && x2 > 0 && y1 < 0 && y2 < 0 {
                        z = z2
                    }
                    else {
                        z = z1
                    }
                    
                    if zdev < 1 {
                        zcorrgate = zdev < 0.5 ? z * (1-zdev) * zcorrgate : z * zcorrgate / (1-zdev)
                    }
                    else if zdev > 1 {
                        zcorrgate = z * zcorrgate * zdev
                    }
                    else{
                        zcorrgate = z * zcorrgate
                    }
                    
                    // BLUE ACTIVATIONS - BOTH POSITIVE X - BLUE & RED-BLUE & YELLOW-BLUE
                    if (x1 > 0 && x2 > 0) {
                        let angle1 = (atan2(x1,y1) * 180.0 / Double.pi)
                        let angle2 = (atan2(x2,y2) * 180.0 / Double.pi)
                        let deltaAngle = abs(angle2 - angle1)
                        
                        var exclusionAngle = 0.0
                        var passCondition : Bool
                        var yPassCondition : Bool?
                        
                        //BLUE-YELLOW - X BOTH POSITIVE WITH NEGATIVE Y
                        if  (y1 < 0 && y2 < 0) {
                            message = "BLUE-YELLOW \(dz1 > 0 && dz2 > 0)"
                            passCondition = true // pass straight through - no need to check for blue-yellow
                            
                            // NB if we are genuinely pressing orange, then Y2 decreases at the same time as z1 and z2 are increasing
                            yPassCondition = dy2 < 0
                            z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2, yPassCondition: yPassCondition!)
                        }
                            // BLUE-RED X BOTH POSITIVE WITH POSITIVE Y
                        else if (y1 > 0 && y2 > 0) {
                            message = "BLUE-RED \(dz1 > 0 && dz2 > 0)"
                            
                            exclusionAngle = 60.0 * (1 - 0.5 * (x1 + x2)) + 2.0
                            passCondition = deltaAngle > exclusionAngle
                            
                            //Catch Red Saturation and block out unintended Y activity
                            if y1 > 0.99 && y2 > 0.99 && z1 < 0.0 && z2 > 0.0 {
                                x = 0
                            }
                        }
                        // BLUE (PURE) X BOTH POSITIVE WITH ZERO Y
                        else if (y1 == 0 && y2 == 0) {
                            message = "BLUE (PURE) \(dz1 > 0 && dz2 > 0)"
                            passCondition = true // pass straight through - no need to check for blue-yellow
                        }
                        // BLUE (IMPURE) X BOTH POSITIVE WITH OPPOSING Y OR Y SINGLE ZERO
                        else {
                            if y1 == 0 || y2 == 0 {
                                message = "BLUE (SINGLE ZERO Y) \(dz1 > 0 && dz2 > 0)"
                                y = y2
                                exclusionAngle = 6.0 * (1 - 0.5 * (x1 + x2)) + 2.0
                            }
                            else {
                                message = "BLUE (OPPOSING Y) \(dz1 > 0 && dz2 > 0)"
                                y = 0 // assume that intention is NOT to activate red or yellow
                                exclusionAngle = 10.0 * (1 - 0.5 * (x1 + x2)) + 2.0
                            }
                            passCondition = deltaAngle > exclusionAngle
                        }
                        // Only do this if we've not already been through BLUE-YELLOW
                        if yPassCondition == nil {
                            message += " : Delta Angle = \(deltaAngle) : exclusionAngle = \(exclusionAngle) :"
                            z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2, withPassCondition: passCondition)
                        }
                    }
                    // GREEN ACTIVATIONS - BOTH NEGATIVE X
                    else if (x1 < 0 && x2 < 0) {
                        //YELLOW-GREEN - X BOTH NEGATIVE WITH NEGATIVE Y
                        let angle1 = (atan2(x1,y1) * 180.0 / Double.pi)
                        let angle2 = (atan2(x2,y2) * 180.0 / Double.pi)
                        let deltaAngle = abs(angle2 - angle1)
                        
                        var exclusionAngle = 0.0
                        var passCondition : Bool
                        var xyPassCondition : Bool?
                        if  (y1 < 0 && y2 < 0) {
                            message = "GREEN-YELLOW \(dz1 > 0 && dz2 > 0)"
                            //HERE WE SET UP A PASS/FAIL CONDITION  SO THAT Z ONLY ALLOWED IF PRESSIMG DOWN (CAUSING MAGNETS TO SEPARATE, DIRECTIONS TO DIVERGE)
                            exclusionAngle = 30.0 * (1 + 0.5 * (x1 + x2)) + 2.0
                            passCondition = deltaAngle > exclusionAngle
                            
                            //Catch Green Saturation and block out unintended Y activity
                            if x1 < -0.99 && x2 < -0.99 && z1 < 0.0 && z2 > 0.0 {
                                y = 0
                            }
                            
                            //Catch Yellow Saturation and block out unintended X activity
                            if y1 < -0.99 && y2 < -0.99 && z1 > 0.99 {
                                x = 0
                            }
                        }
                        // RED-GREEN - X BOTH NEGATIVE WITH POSITIVE Y
                        else if (y1 > 0 && y2 > 0) {
                            message = "GREEN-RED \(dz1 > 0 && dz2 > 0)"
                            xyPassCondition = (dx1 < 0 && dx2 > 0) || (dy1 >= 0 && dy2 <= 0)
                            message =  message + " xPassCondition: \(String(describing: xyPassCondition))"
                            z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2, yPassCondition: xyPassCondition!)
                            passCondition = true // pass straight through - no need to check for red-green
                        }
                            // PURE GREEN - X BOTH NEGATIVE WITH BOTH Y VALUES EQUAL TO ZERO
                        else if (y1 == 0 && y2 == 0) {
                            message = "GREEN (PURE) \(dz1 > 0 && dz2 > 0)"
                            passCondition = true // pass straight through - no need to check for pure green
                        }
                        // GREEN (MESSY) - X BOTH NEGATIVE WITH OPPOSING Y (+/-, -/+), OR A SINGLE Y VALUE EQUAL TO ZERO
                        else  { // Do we want to separate into +/- vs +/0 cases for greater control?
                            // Intention of this interaction is either to press green or to press orange with a green bias (+/-, -,+).
                            y = y1
                            let xVal = -0.5 * (x1 + x2)
                            if y1 == 0 || y2 == 0 {
                                message = "GREEN (SINGLE ZERO Y) \(dz1 > 0 && dz2 > 0)"
                                exclusionAngle = 10.0 * (1 - xVal) + 2.0
                                xyPassCondition = (dx1 < 0 && dx2 > 0) || (dy1 >= 0 && dy2 <= 0)
                                message =  message + " xPassCondition: \(String(describing: xyPassCondition))"
                                z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2, yPassCondition: xyPassCondition!)
                            }
                            else {
                                message = "GREEN (OPPOSING Y) \(dz1 > 0 && dz2 > 0)"
                                exclusionAngle = 20.0 * (1 - xVal) + 2.0
                                xyPassCondition = (dx1 < 0 && dx2 > 0) || (dy1 >= 0 && dy2 <= 0)
                                message =  message + " xPassCondition: \(String(describing: xyPassCondition))"
                                z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2, yPassCondition: xyPassCondition!)
                            }
                            message += ": xVal = \(xVal)"
                            passCondition = deltaAngle > exclusionAngle
                        }
                        message += " : Delta Angle = \(deltaAngle) : exclusionAngle = \(exclusionAngle)"
                        // Only do this if we've not already been through BLUE-YELLOW
                        if xyPassCondition == nil {
                            z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2, withPassCondition: passCondition)
                        }
                    }
                    /* OPPOSING X VALUES (+/-, -/+) WE ARE IN A BOTH-NON-ZERO-X BLOCK HERE.
                     * X +/-, -/+ PROBABLY PRESSING DOWN AND NOT INTENDING TO TRIGGER BLUE OR GREEN SIDES
                     */
                    else {
                        //RED-ISH
                        if y1 > 0 && y2 > 0 {
                            x = 0
                            message = "RED (MESSY X) \(dz1 > 0 && dz2 > 0)"
                        }
                            // YELLOW-ISH
                        else if y1 < 0 && y2 < 0 {
                            x = 0
                            message = "YELLOW (MESSY X) \(dz1 > 0 && dz2 > 0)"
                        }
                            // Y BOTH ZERO
                        else if y1 == 0 && y2 == 0 {
                            x = 0
                            message = "ORANGE (MESSY X) \(dz1 > 0 && dz2 > 0)"
                        }
                            // Y OPPOSING, OR SINGLE ZERO-Y
                        else {
                            x = 0
                            y = 0
                            message = "ORANGE (MESSY X + Y 1) \(dz1 > 0 && dz2 > 0)"
                        }
                        z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2)
                    }
                }
                // ONE OR BOTH SENSORS ZERO ON X
                else {
                    // ONE OR BOTH SENSORS ZERO ON X & BOTH SENSORS NON-ZERO ON Y
                    if !y1.isZero && !y2.isZero {
                        // RED ACTIVATIONS - Y BOTH POSITIVE AND ONE OR BOTH SENSORS ZERO ON X
                        if y1 > 0 && y2 > 0 {
                            message = "RED \(dz1 > 0 && dz2 > 0)"
                            if (x1 == 0 && x2 == 0) {
                                message =  message + " (X BOTH ZERO)"
                            }
                            else {
                                x = x1
                                message =  message + " (X ONE ZERO)"
                            }
                            z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2)
                            x1sum = 0
                            x2sum = 0
                        }
                            // YELLOW ACTIVATIONS - BOTH NEGATIVE Y AND ONE OR BOTH SENSORS ZERO ON X
                        else if (y1 < 0 && y2 < 0){
                            message = "YELLOW \(dz1 > 0 && dz2 > 0)"
                            if (x1 == 0 && x2 == 0) {
                                message =  message + " (X BOTH ZERO)"
                            }
                            else {
                                x = x2
                                message =  message + " (X ONE ZERO)"
                            }
                            // NB if we are genuinely pressing orange, then Y2 decreases at the same time as z1 and z2 are increasing
                            let yPassCondition = dy2 < 0
                            z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2, yPassCondition: yPassCondition)
                        }
                        /* OPPOSING Y VALUES (+/-, -/+) AND ONE OR BOTH SENSORS ZERO ON X.
                         * WE ARE IN A BOTH-NON-ZERO-Y BLOCK HERE.
                         * PROBABLY PRESSING DOWN AND NOT INTENDING TO TRIGGER YELLOW OR RED SIDES
                         */
                        else {
                            x = 0
                            y = 0
                            message = "ORANGE (MESSY X + Y 2) \(dz1 > 0 && dz2 > 0)"
                            z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2)
                        }
                    }
                        // ONE OR BOTH SENSORS ZERO ON X & ONE OR BOTH SENSORS ZERO ON Y
                    else {
                        message = "ORANGE \(dz1 > 0 && dz2 > 0) "
                        if x1 == 0 && x2 == 0 {
                            message =  message + " (X BOTH ZERO)"
                        }
                        else {
                            message =  message + " (X ONE ZERO)"
                            //Permit light x-activation for stiff foam heads - do NOT need to set x to zero here - hence commented so we dont consider it again
                        }
                        
                        if y1 == 0 && y2 == 0 {
                            message = message + " + (Y BOTH ZERO)"
                        }
                        else {
                            message = message + " + (Y ONE ZERO)"
                        }
                        
                        if dz1 == 0 && dz2 != 0 {
                            //use dz2 for both z velocities
                            message = message + " sensor [0 1] >>>"
                            z = getZFromVelocity(debug: message, dz1: dz1, dz2: dz2) // this version triggers on dz2 only, but still accumulates dz1
                        }
                        else {
                            message = message + " sensor [1 1]"
                            z = getZFromVelocity(debug: message, z1: z1, z2: z2, dz1: dz1, dz2: dz2)
                        }
                    }
                }
                getRadiusAndAngle(x, y, z)
                decodeAngle3() // determine angle and radius, and therefore the active zone
                // Then we can route the signals to any delegate listening for updates
                // MARK: use routeMono() for Playgrounds, Skratch and Bluetooth MIDI
                routeMono()
                // MARK: use routeSignals2() for Skoog iOS
            }
        }
    }
    
    func getRadiusAndAngle(_ x: Double,_ y: Double,_ z: Double) {
        Z3 = z <= 0.999999 ? z : 0.999999
        R1 = getMagnitude(x, y: y)
        T1 = radToDegrees(atan2(x, y)) + 180.0
        R2 = R1
        T2 = T1
    }
    
    func getXFromVelocity(debug: String, x1: Double, x2: Double, dx1: Double, dx2: Double) -> Double {
        //  BOTH VELOCITIES POSITIVE  OR ACCUMULATED DISPLACEMENT  OR  X1 SATURATED AND X2 VEL POSITIVE OR X2 SATURATED AND X1 VEL POSITIVE
        let x : Double
        var message = debug
        
        if (dx1 > 0.0078 && dx2 >= 0.0) || (dx1 >= 0.0 && dx2 > 0.0078) || (x1sum > 0 && x2sum > 0)
        {
            if (dx1 > 0.0078 && dx2 >= 0.0) {
                self.x1sum += (self.x1sum + dx1) <= 1.0 ? dx1 : 0.0
                self.x2sum = self.x1sum
            }
            else if (dx1 >= 0.0 && dx2 > 0.0078) {
                self.x2sum += (self.x2sum + dx2) <= 1.0 ? dx2 : 0.0
                self.x1sum = self.x2sum
            }
            else {
                self.x1sum += (self.x1sum + dx1) <= 1.0 ? dx1 : 0.0
                self.x2sum += (self.x2sum + dx2) <= 1.0 ? dx2 : 0.0
            }
            
            x = 0.5 * (self.x1sum + self.x2sum)
            message = "X-PASS " + message
        }
        else {
            message = "X-BLOCKING \(dx1) \(dx2)" + message
            self.x1sum = 0
            self.x2sum = 0
            x = 0
        }
        
        print("\(message)  >>>  x \(String(format: "%.2f",  x)))")
        return x
        
    }
    
    func getYFromVelocity(debug: String, y1: Double, y2: Double, dy1: Double, dy2: Double) -> Double{
        //  BOTH VELOCITIES POSITIVE  OR ACCUMULATED DISPLACEMENT  OR  Z1 SATURATED AND Z2 VEL POSITIVE OR Z2 SATURATED AND Z1 VEL POSITIVE
        let y : Double
        var message = debug
        
        if (dy1 > 0.008 && dy2 > 0.008) || (y1sum > 0 && y2sum > 0)
            || (y1 > 0.99 && dy2 > 0.008) || (y2 > 0.99 && dy1 > 0.008)
        {
            // CORRECT FOR Z1 SATURATION HERE:
            if (y1 > 0.99 && dy2 > 0.008) {
                self.y2sum += (self.y2sum + dy2) <= 1.0 ? dy2 : 0.0
                self.y1sum = self.y2sum
                message += " Y1 MAXXED OUT!!!"
            }
                // CORRECT FOR Z2 SATURATION HERE:
            else if (y2 > 0.99 && dy1 > 0.008) {
                self.y1sum += (self.z1sum + dy1) <= 1.0 ? dy1 : 0.0
                self.y2sum = self.y1sum
                message += " Y2 MAXXED OUT!!!"
            }
            else  {
                self.y1sum += (self.y1sum + dy1) <= 1.0 ? dy1 : 0.0
                self.y2sum += (self.y2sum + dy2) <= 1.0 ? dy2 : 0.0
            }
            y = 0.5 * (self.y1sum + self.y2sum)
            message = "PASS " + message
        }
        else {
            message = "BLOCKING " + message
            self.y1sum = 0
            self.y2sum = 0
            y = 0
        }
        
        print("\(message)  >>>  y \(String(format: "%.2f",  y)))")
        return y
        
    }
    
    func getZFromVelocity(debug: String, dz1: Double, dz2: Double) -> Double{
        //  BOTH VELOCITIES POSITIVE  OR ACCUMULATED DISPLACEMENT  OR  Z1 SATURATED AND Z2 VEL POSITIVE OR Z2 SATURATED AND Z1 VEL POSITIVE
        let z : Double
        var message = debug
        let vel_thresh = 0.008
        if (dz2 > vel_thresh) || (z2sum > 0)
        {
            message = "Z-PASS " + message
            self.z2sum += (self.z2sum + dz2) <= 1.0 ? dz2 : 0.0
            self.z1sum += (self.z1sum + dz1) <= 1.0 ? dz1 : 0.0
            z = 0.5 * (self.z1sum + self.z2sum)
        }
        else {
            message = "Z-BLOCKING " + message
            self.z2sum = 0
            self.z1sum = 0
            z = 0
        }
        
        print("\(message)  >>>  z \(String(format: "%.2f",  z)))")
        return z
        
    }
    
    func getZFromVelocity(debug: String, z1: Double, z2: Double, dz1: Double, dz2: Double) -> Double{
        //  BOTH VELOCITIES POSITIVE  OR ACCUMULATED DISPLACEMENT  OR  Z1 SATURATED AND Z2 VEL POSITIVE OR Z2 SATURATED AND Z1 VEL POSITIVE
        let z : Double
        var message = debug
        let vel_thresh = 0.016
        if (dz1 > vel_thresh && dz2 > vel_thresh) || (z1sum > 0 && z2sum > 0)
            || (z1 > 0.99 && dz2 > vel_thresh) || (z2 > 0.99 && dz1 > vel_thresh)
        {
            // CORRECT FOR Z1 SATURATION HERE:
            if (z1 > 0.99 && dz2 > 0.008) {
                self.z2sum += (self.z2sum + dz2) <= 1.0 ? dz2 : 0.0
                self.z1sum = self.z2sum
                message += " Z1 MAXXED OUT!!!"
            }
                // CORRECT FOR Z2 SATURATION HERE:
            else if (z2 > 0.99 && dz1 > 0.008) {
                self.z1sum += (self.z1sum + dz1) <= 1.0 ? dz1 : 0.0
                self.z2sum = self.z1sum
                message += " Z2 MAXXED OUT!!!"
            }
            else  {
                self.z1sum += (self.z1sum + dz1) <= 1.0 ? dz1 : 0.0
                self.z2sum += (self.z2sum + dz2) <= 1.0 ? dz2 : 0.0
            }
            z = 0.5 * (self.z1sum + self.z2sum)
            message = "Z-PASS " + message
        }
        else {
            message = "Z-BLOCKING " + message
            self.z1sum = 0
            self.z2sum = 0
            z = 0
        }
        
        print("\(message)  >>>  z \(String(format: "%.2f",  z)))")
        return z
        
    }
    
    func getZFromVelocity(debug: String, z1: Double, z2: Double, dz1: Double, dz2: Double, yPassCondition: Bool) -> Double{
        //  BOTH VELOCITIES POSITIVE  OR ACCUMULATED DISPLACEMENT  OR  Z1 SATURATED AND Z2 VEL POSITIVE OR Z2 SATURATED AND Z1 VEL POSITIVE
        let z : Double
        var message = debug
        let vel_thresh = 0.016
        if (dz1 > vel_thresh && dz2 > vel_thresh && yPassCondition) || (z1sum > 0 && z2sum > 0)
            || (z1 > 0.99 && dz2 > vel_thresh && yPassCondition) || (z2 > 0.99 && dz1 > vel_thresh && yPassCondition)
        {
            // CORRECT FOR Z1 SATURATION HERE:
            if (z1 > 0.99 && dz2 > 0.008) {
                self.z2sum += (self.z2sum + dz2) <= 1.0 ? dz2 : 0.0
                self.z1sum = self.z2sum
                message += " Z1 MAXXED OUT!!!"
            }
                // CORRECT FOR Z2 SATURATION HERE:
            else if (z2 > 0.99 && dz1 > 0.008) {
                self.z1sum += (self.z1sum + dz1) <= 1.0 ? dz1 : 0.0
                self.z2sum = self.z1sum
                message += " Z2 MAXXED OUT!!!"
            }
            else  {
                self.z1sum += (self.z1sum + dz1) <= 1.0 ? dz1 : 0.0
                self.z2sum += (self.z2sum + dz2) <= 1.0 ? dz2 : 0.0
            }
            z = 0.5 * (self.z1sum + self.z2sum)
            message = "Z-PASS " + message
        }
        else {
            message = "Z-BLOCKING " + message
            self.z1sum = 0
            self.z2sum = 0
            z = 0
        }
        
        print("\(message)  >>>  z \(String(format: "%.2f",  z)))")
        return z
        
    }
    
    func getZFromVelocity(debug: String, z1: Double, z2: Double, dz1: Double, dz2: Double, withPassCondition: Bool?) -> Double{
        //  BOTH VELOCITIES POSITIVE  OR ACCUMULATED DISPLACEMENT  OR  Z1 SATURATED AND Z2 VEL POSITIVE OR Z2 SATURATED AND Z1 VEL POSITIVE
        let z : Double
        let passCondition = withPassCondition
        var message = debug
        let vel_thresh = 0.016
        if (dz1 > vel_thresh && dz2 > vel_thresh && passCondition!) || (z1sum > 0 && z2sum > 0 && passCondition!)
            || (z1 > 0.99 && dz2 > vel_thresh && passCondition!) || (z2 > 0.99 && dz1 > vel_thresh && passCondition!)
        {
            // CORRECT FOR Z1 SATURATION HERE:
            if (z1 > 0.99 && dz2 > 0.008) {
                self.z2sum += (self.z2sum + dz2) <= 1.0 ? dz2 : 0.0
                self.z1sum = self.z2sum
                message += " Z1 MAXXED OUT!!!"
            }
            // CORRECT FOR Z2 SATURATION HERE:
            else if (z2 > 0.99 && dz1 > 0.008) {
                self.z1sum += (self.z1sum + dz1) <= 1.0 ? dz1 : 0.0
                self.z2sum = self.z1sum
                message += " Z2 MAXXED OUT!!!"
            }
            else  {
                self.z1sum += (self.z1sum + dz1) <= 1.0 ? dz1 : 0.0
                self.z2sum += (self.z2sum + dz2) <= 1.0 ? dz2 : 0.0
            }
            z = 0.5 * (self.z1sum + self.z2sum)
            message = "Z-PASS " + message
        }
        else {
            message = "Z-BLOCKING " + message
            self.z1sum = 0
            self.z2sum = 0
            z = 0
        }
        
        
        print("\(message)  >>>  z \(String(format: "%.2f",  z))) with Pass Condition \(String(describing: passCondition)) ")
        return z
        
    }
    
    // MARK:  Cross Correlation
    func xcorrelate_normalised(array1: [Int], array2: [Int]) {
        var j1 = 0
        //        var j2 = 0
        var k1 = 0
        var k2 = 0
        var i = 0
        var xcorr = Array(repeating: 0.0, count: 2 * bufferSize - 1)
        while i < (2 * bufferSize - 1) {
            var sum = 0.0
            if i > (bufferSize - 1){
                k1 = 2 * bufferSize - 2 - i
                k2 = bufferSize - 1
                for n in 0 ... k1 {
                    //print("IF: array1 element \(n) array2 element \(k2 - (k1 - n))")
                    sum += Double (array1[n] * array2[k2 - (k1 - n)])
                    sum /=  sqrt(Double (array1[n] * array1[n] * array2[k2 - (k1 - n)] * array2[k2 - (k1 - n)]))
                }
                xcorr[i] = Double(sum)
            }
            else {
                j1 = bufferSize - i - 1;
                k1 = bufferSize -    1;
                for n in j1 ... k1 {
                    //print("ELSE: array1 element \(n) array2 element \(n - j1)")
                    sum += Double (array1[n] * array2[n - j1])
                    sum /=  sqrt(Double (array1[n] * array1[n] * array2[n - j1] * array2[n - j1]))
                    
                }
                xcorr[i] = Double(sum)
            }
            i += 1
        }
        
        
        //return xcorr
        //        print("xcorr: \(xcorr)")
        //        print("xcorr max \(xcorr.max())")
    }
    
    func xcorrelate_bignorm(array1: [Int], array2: [Int]) -> Double {
        var j1 = 0
        //        var j2 = 0
        var k1 = 0
        var k2 = 0
        var i = 0
        var xcorr = Array(repeating: 0.0, count: 2 * bufferSize - 1)
        while i < (2 * bufferSize - 1) {
            var sum = 0.0
            if i > (bufferSize - 1){
                k1 = 2 * bufferSize - 2 - i
                k2 = bufferSize - 1
                for n in 0 ... k1 {
                    //print("IF: array1 element \(n) array2 element \(k2 - (k1 - n))")
                    sum += Double (array1[n] * array2[k2 - (k1 - n)])
                    sum /=  abs(array1[n]) >= abs(array2[k2 - (k1 - n)])
                        ? Double (array1[n] * array1[n])
                        : Double (array2[k2 - (k1 - n)] * array2[k2 - (k1 - n)])
                }
                xcorr[i] = Double(sum)
            }
            else {
                j1 = bufferSize - i - 1;
                k1 = bufferSize -    1;
                for n in j1 ... k1 {
                    //print("ELSE: array1 element \(n) array2 element \(n - j1)")
                    sum += Double (array1[n] * array2[n - j1])
                    sum /= abs(array1[n]) >= abs(array2[n - j1])
                        ? Double (array1[n] * array1[n])
                        : Double (array2[n - j1] * array2[n - j1])
                }
                xcorr[i] = Double(sum)
            }
            i += 1
        }
        
        var xcorrsum = 0.0;
        for n in 0 ... xcorr.count - 1 {
            if xcorr[n].isFinite{
                xcorrsum += xcorr[n]
            }
        }
        
        //        print("max \(xcorr.max()) : sum/n = \(xcorrsum/Double(xcorr.count))")
        
        return xcorrsum/Double(xcorr.count)
    }
    
    /**********************************************************************************************
     *
     * Correlation between input values, normalised relative to the biggest input Needs Z as input 1
     * - equivalent to ratio of the r to z where r < z.  If r > z, then we force the result to be small
     * by dividing the product of the inputs by the [maximum input value squared???]
     *
     * Eg If inputs are z1 and r1, with r1 = 0.5*z1 => z1>r1, sum = r1/z1 = 0.5*z1*z1/z1*z1 = 0.5 = 50%
     *    If z1 = 0.5*r1, sum = 0.5*r1*r1/100
     *
     **********************************************************************************************/
    
    func xcorrelate_Znorm(Zarray1: [Int], array2: [Int]) -> Double {
        var j1 = 0
        //        var j2 = 0
        var k1 = 0
        var k2 = 0
        var i = 0
        var xcorr = Array(repeating: 0.0, count: 2 * bufferSize - 1)
        while i < (2 * bufferSize - 1) {
            var sum = 0.0
            if i > (bufferSize - 1){
                k1 = 2 * bufferSize - 2 - i
                k2 = bufferSize - 1
                for n in 0 ... k1 {
                    //                    print("IF: array1 element \(n) array2 element \(k2 - (k1 - n))")
                    sum += Double (Zarray1[n] * array2[k2 - (k1 - n)])
                    //                    sum /=  abs(array1[n]) >= abs(array2[k2 - (k1 - n)])
                    //                        ? Double (array1[n] * array1[n])
                    //                        : Double (100.0)
                    sum /=  Double (Zarray1[n] * Zarray1[n])
                    
                }
                xcorr[i] = Double(sum)
            }
            else {
                j1 = bufferSize - i - 1;
                k1 = bufferSize -    1;
                for n in j1 ... k1 {
                    //                    print("ELSE: array1 element \(n) array2 element \(n - j1)")
                    sum += Double (Zarray1[n] * array2[n - j1])
                    //                    sum /= abs(array1[n]) >= abs(array2[n - j1])
                    //                        ? Double (array1[n] * array1[n])
                    //                        : Double (100.0)
                    sum /= Double (Zarray1[n] * Zarray1[n])
                }
                xcorr[i] = Double(sum)
            }
            i += 1
        }
        
        var xcorrsum = 0.0;
        for n in 0 ... xcorr.count - 1 {
            if xcorr[n].isFinite{
                xcorrsum += xcorr[n]
            }
        }
        
        //        print("array: \(xcorr) max: \(xcorr.max()) : sum/n = \(xcorrsum/Double(xcorr.count))")
        
        let result = xcorrsum/Double(xcorr.count)
        return result.isFinite ? result : 0.0
    }
    
    
    func xcorrelate_smallnorm(array1: [Int], array2: [Int]) -> Double {
        var j1 = 0
        //        var j2 = 0
        var k1 = 0
        var k2 = 0
        var i = 0
        var xcorr = Array(repeating: 0.0, count: 2 * bufferSize - 1)
        while i < (2 * bufferSize - 1) {
            var sum = 0.0
            if i > (bufferSize - 1){
                k1 = 2 * bufferSize - 2 - i
                k2 = bufferSize - 1
                for n in 0 ... k1 {
                    //print("IF: array1 element \(n) array2 element \(k2 - (k1 - n))")
                    sum += Double (array1[n] * array2[k2 - (k1 - n)])
                    sum /=  abs(array1[n]) <= abs(array2[k2 - (k1 - n)])
                        ? Double (array1[n] * array1[n])
                        : Double (array2[k2 - (k1 - n)] * array2[k2 - (k1 - n)])
                }
                xcorr[i] = Double(sum)
            }
            else {
                j1 = bufferSize - i - 1;
                k1 = bufferSize -    1;
                for n in j1 ... k1 {
                    //print("ELSE: array1 element \(n) array2 element \(n - j1)")
                    sum += Double (array1[n] * array2[n - j1])
                    sum /= abs(array1[n]) <= abs(array2[n - j1])
                        ? Double (array1[n] * array1[n])
                        : Double (array2[n - j1] * array2[n - j1])
                }
                xcorr[i] = Double(sum)
            }
            i += 1
        }
        
        var xcorrsum = 0.0;
        for n in 0 ... xcorr.count - 1 {
            if xcorr[n].isFinite{
                xcorrsum += xcorr[n]
            }
        }
        
        return xcorrsum/Double(xcorr.count)
    }
    
    
    
    func xcorrelate(array1: [Int], array2: [Int]) -> Array<Double> {
        //        let before = CACurrentMediaTime()
        
        
        var j1 = 0
        //        var j2 = 0
        var k1 = 0
        var k2 = 0
        var i = 0
        let buffersize = 8;//TBC
        var xcorr = Array(repeating: 0.0, count: 2 * buffersize - 1)
        while i < (2 * buffersize - 1) {
            var sum = 0
            if i > (buffersize - 1){
                k1 = 2 * buffersize - 1 - i
                k2 = buffersize - 1
                for n in 0 ... k1 {
                    sum += array1[n] * array2[k2 - (k1 - n)]
                }
                xcorr[i] = Double(sum)
            }
            else {
                j1 = buffersize - i - 1;
                k1 = buffersize -    1;
                for n in j1 ... k1 {
                    sum += array1[n] * array2[n - j1]
                }
                xcorr[i] = Double(sum)
            }
            i += 1
        }
        //        let after = CACurrentMediaTime()-before
        //        print("Time to run xcorr method: \(after)")
        //        print("xcorr: \(xcorr)")
        //        print("xcorr max \(xcorr.max())")
        return xcorr
    }
    
    
    func handle(_ packet:MIDIPacket) {
        if packet.data.1 == 102 &&
            packet.data.4 == 103 &&
            packet.data.7 == 104 &&
            packet.data.10 == 105 &&
            packet.data.13 == 106 &&
            packet.data.16 == 107 &&
            packet.data.19 == 108 {
            
            if !calibrating {
                self.themidipacket[0] = Int(packet.data.2)
                self.themidipacket[1] = Int(packet.data.5)
                self.themidipacket[2] = Int(packet.data.8)
                self.themidipacket[3] = Int(packet.data.11)
                self.themidipacket[4] = Int(packet.data.14)
                self.themidipacket[5] = Int(packet.data.17)
                self.themidipacket[6] = Int(packet.data.20)
                packetCount += 1
                currentPacket = CACurrentMediaTime()
                currentTime = currentPacket
                
                if currentTime-lastTime >= 1.0 {
                    packetCount = 0
                    lastTime = CACurrentMediaTime()
                }
                lastPacket = currentPacket
                preprocess(packet)
                
                // hold a buffer of previous values for the magnetic field strength
                magFieldStrengthBuffer.remove(at: bufferSize - 1)
                magFieldStrengthBuffer.insert(Int(self.themidipacket[6]), at: 0)
                // if there's a suspected glitch where the value of z2 infects the magFieldStrength channel...
                if self.themidipacket[6] == self.themidipacket[5] && self.themidipacket[6] != 0 {
                    // run a median filter to clear up the signals
                    magFieldStrengthBuffer[0] = medianFilter(array: magFieldStrengthBuffer)[1]
                }
                checkCompass(value: magFieldStrengthBuffer[0])
            }
        }
    }
    
    func checkCompass(value: Int){
        if value > self.magnetThreshold && value != 252 && self.firmwareMajorVersion > 0 {
            if canShowWarning {
                //                self.delegate?.showMagnetWarning()
                canShowWarning = false
            }
        }
        else {
            canShowWarning = true
        }
    }
    
    // MARK: Helper methods
    public func initialiseSkoog() {
        setPolyMode(active: self.polyMode)
        // and anything else that needs doing...
    }
    
    public func setPolyMode(active: Bool) {
        //        print("Setting mono/Poly mode")
        if active {
            if firmwareMajorVersion > 0 && firmwareMinorVersion > 0 {
                self.XYcone = 16.0
                self.ZconeZ = 30.0
                self.ZconeXY = 10
                self.polyMode = true
            }
            else {
                self.XYcone = 16.0
                self.ZconeZ = 16.5
                self.ZconeXY = 10
                self.polyMode = true
            }
        }
        else {
            if firmwareMajorVersion > 0 && firmwareMinorVersion > 0 {
                self.XYcone = 45.0
                self.ZconeZ = 45.0
                self.ZconeXY = 45.0
                self.polyMode = false
            }
            else {
                self.XYcone = 45.0
                self.ZconeZ = 45.0
                self.ZconeXY = 30
                self.polyMode = false
            }
        }
        changeXYcone(self.XYcone)
    }
    
    public func getSkoogConnected()->Bool {
        return self.skoogConnected
    }
    
    func getMagnitude(_ x:Double, y:Double)->Double
    {
        return sqrt(x * x + y * y)
    }
    
    func radToDegrees(_ radians:Double)->Double
    {
        return radians * 180.0 / Double.pi
    }
    
    func degToRadians(_ degrees:Double)->Double
    {
        return Double.pi * degrees / 180
    }
    
    func cosAplusB(_ a:Double, b:Double)->Double
    {
        return cos(a) * cos(b) - sin(a) * sin(b)
    }
    
    func cosAminusB(_ a:Double, b:Double)->Double
    {
        return cos(a) * cos(b) + sin(a) * sin(b)
    }
    
    func sinAplusB(_ a:Double, b:Double)->Double
    {
        return sin(a) * cos(b) + sin(b) * cos(a)
    }
    
    func sinAminusB(_ a:Double, b:Double)->Double
    {
        return sin(a) * cos(b) - sin(b) * cos(a)
    }
    
    func gatedLowPass(_ newinput:Double, oldinput:Double, alpha:Double, LPthreshold:Double, LPgate:Double)->Double
    {
        if newinput < LPthreshold
        {
            if newinput < LPgate
            {
                return 0.0
            }
            else
            {
                return  alpha * newinput + (1.0 - alpha) * oldinput
            }
        }
        else
        {
            return newinput
        }
    }
    
    func diffLowPass(_ newinput:Double, oldinput :Double, alpha:Double, LPdiff:Double)->Double
    {
        if fabs(newinput-oldinput) < LPdiff
        {
            return  alpha * newinput + (1.0 - alpha) * oldinput
        }
        else
        {
            return newinput
        }
    }
    
    func variableLowPass(_ newinput:Double, oldinput:Double, alpha:Double, LPthreshold:Double, LPgate:Double)->Double
    {
        if (newinput < (3.0 * LPgate))
        {
            if (newinput < (0.25 * LPgate))
            {
                return 0.0
            }
            else
            {
                let varalpha = ((1.0 - 0.000001) * alpha / (2.75 * LPgate)) * newinput + (1 - 3.0*(1.0 - 0.000001)/2.75) * alpha
                return  varalpha * newinput + (1.0 - varalpha) * oldinput
            }
        }
        else
        {
            return alpha * newinput + (1.0 - alpha) * oldinput
        }
    }
    
    func variableDiffLowPass(_ newinput:Double, lastoutput:Double, alpha:Double, LPdiff:Double, signalstrength:Double, LPgate:Double)->Double {
        let change = fabs(newinput-lastoutput)
        if change < LPdiff {
            if change < 35.0 {
                var varalpha = alpha * change / 35.0       // Linear Alpha Variation
                
                if signalstrength < (3.0 * LPgate) {
                    varalpha *= signalstrength / (3.0 * LPgate)
                }
                return  varalpha * newinput + (1.0 - varalpha) * lastoutput
            }
            else {
                return  alpha * newinput + (1.0 - alpha) * lastoutput
            }
        }
        else {
            return newinput
        }
    }
    
    // scale the input sensor values and make sure they don't exceed 1 or go below 0
    func zoom(_ x:Double, y:Double)->Double {
        if x * y > 0.999999 {
            return 0.999999
        }
        else if x * y < 0.0000001 {
            return 0.0000001
        }
        else {
            return x * y
        }
    }
    
    func changeXYcone(_ angle:Double) {
        XYcone = angle
        coneAngle = 90.0 - (2.0 * angle)
        redBlueAngle = 180.0 + angle
        redGreenAngle = 90.0 + angle
        blueYellowAngle = 270.0 + angle
        yellowGreenAngle = angle
    }
    
    func calculateResponse (amount: Double, input: Double)->Double {
        return input / (pow(2, -amount) * (1.0 - input) + input)
    }
    
    func invertResponse(amount : Double, input : Double, invertPercentage: Double)->Double {
        return input / (pow(2, amount * invertPercentage) * (1.0 - input) + input)
    }

    // MARK: Decode MIDI packets
    func decodeAngle() {
        T1 = diffLowPass(T1, oldinput: T1_old, alpha: 0.05, LPdiff: 45.0)
        T2 = diffLowPass(T2, oldinput: T2_old, alpha: 0.05, LPdiff: 45.0)
        
        // Correction to angle for single sensor activation scenarios
        if R1 == 0.0 && R2 > 0.0 {
            T1 = T2
        }
        else if R1 > 0.0 && R2 == 0 {
            T2 = T1
        }
        
        R1 = variableLowPass(zoom(R1, y: R_zoom), oldinput: R1_old, alpha: 0.045, LPthreshold: 1.5, LPgate: zoom(0.023622, y: R_zoom))
        R2 = variableLowPass(zoom(R2, y: R_zoom), oldinput: R2_old, alpha: 0.045, LPthreshold: 1.5, LPgate: zoom(0.023622, y: R_zoom))
        
        // calculate RMS Rxy from sensors 1 and 2
        Rxy = 0.5.squareRoot() * getMagnitude(R1, y: R2)
        
        T1 = variableDiffLowPass(T1, lastoutput: T1_old, alpha: 0.166, LPdiff: 45.0, signalstrength:Rxy, LPgate: zoom(0.023622, y: R_zoom))
        Txy = T1
        Z3 = gatedLowPass(zoom(Z3, y: R_zoom), oldinput: Z3_old, alpha: 0.052, LPthreshold: 1.5, LPgate: z_threshold)
        Rxyz = getMagnitude(Rxy, y: Z3)
        setThresholdZoom(thresholdZoom: 0.0014, z_thresholdZoom: 0.0014)
        
        if didCrossThreshold() {
            normaliseOutput() // re-scale Rxyz, Rxy, and Z3 values between 0 and 1 if necessary
            
            Tz = radToDegrees(atan2(Z3, Rxy))
            // Rxyz will be recalculated in if Txy < 180.0 || Txy > (360.0 - XYcone) && Tz < 90.0 below. Should it be recalculated anywhere else
            
            if lastZone != .none {
                if (lastZone == .green_side || lastZone == .yellow_side ||
                    lastZone == .orange_red_green || lastZone == .orange_yellow_green ||
                    lastZone == .orange_red_blue || lastZone == .orange_blue_yellow ||
                    lastZone == .orange_red || lastZone == .orange_blue ||
                    lastZone == .orange_yellow || lastZone == .orange_green) && Rxy == 0.0 && Tz == 90.0
                {
                    blocking = true
                }
                
                if blocking {
                    Z3 = 0.0
                    Tz = Tz_old
                }
                Tz = diffLowPass(Tz, oldinput: Tz_old, alpha: 0.166, LPdiff: 91.0)
            }
            else {
                blocking = false
                Tz = diffLowPass(Tz, oldinput: Tz_old, alpha: 0.95, LPdiff: 91.0)
            }
            
            var m : Double = 0.85
            var c : Double = 23.6
            var correction_factor_XY : Double = 0.0
            
            if Txy < 180.0 || Txy > (360.0 - XYcone) && Tz < 90.0 {
                if Tz > 74.6 {
                    m = 0.2916
                    c = 58.2633
                }
                
                correction_factor_XY = sin(degToRadians(Txy)) + 1.0 * (((Txy < 45.0 || Txy > 315.0)) ? cos(degToRadians(2.0 * Txy)) : 0.0)
                
                Tz_corrected = Tz * (1.0 - correction_factor_XY * (1.0 - 1.0 / m)) - correction_factor_XY * c / m
                
                if (Tz_corrected <= 0.0) {
                    Tz_corrected    = 0.000000001
                    ZC              = 0.000000001
                }
                else if (Tz_corrected >= 78.5) { // Above 78.5 tanf blows up.
                    Tz_corrected = Tz
                    ZC = Z3
                }
                else {
                    ZC = Rxy * tan(degToRadians(Tz_corrected))
                }
                Rxyz = getMagnitude(Rxy, y: ZC)
            }
            else {
                ZC = Z3
                Tz_corrected = Tz
            }
            findActiveZone(Tz: Tz_corrected)
        }
        else {
            resetAngleData()
        }
        storeOldValues()
    }
    
    func decodeAngle2() {
        T1 = diffLowPass(T1, oldinput: T1_old, alpha: 0.85, LPdiff: 45.0)
        T2 = diffLowPass(T2, oldinput: T2_old, alpha: 0.85, LPdiff: 45.0) // probably useless
        
        // Correction to angle for single sensor activation scenarios - probably useless
        if R1 == 0.0 && R2 > 0.0 {
            T1 = T2
        }
        else if R1 > 0.0 && R2 == 0 {
            T2 = T1
        }
        
        // R1 has been set in the preprocess method
        // R2 has been set in the preprocess method
        
        // calculate average Rxy from sensors 1 and 2 (clamp output if above 1.0) - R1 == R2 so this is probably pointless
        Rxy = (0.0...1.0).clamp(value: 0.5 * (R1 + R2))
        
        // we've done a diffLowPass, so why not a variableDiffLowPass, eh? eh? ...anyone?
        T1 = variableDiffLowPass(T1, lastoutput: T1_old, alpha: 0.5, LPdiff: 45.0, signalstrength:Rxy, LPgate: zoom(0.023622, y: R_zoom))
        Txy = T1
        
        // Z3 has been set in the preprocess method
        
        Rxyz = getMagnitude(Rxy, y: Z3)
        setThresholdZoom(thresholdZoom: 0.012, z_thresholdZoom: 0.012) // would like to set this once when we get firmware version, not for every packet
        
        if didCrossThreshold() {
            normaliseOutput() // re-scale Rxyz, Rxy, and Z3 values between 0 and 1 if necessary
            Tz = radToDegrees(atan2(Z3, Rxy))
            Rxyz = (0.0...1.0).clamp(value: getMagnitude(Rxy, y: Z3))
            findActiveZone(Tz: Tz)
        }
        else {
            resetAngleData()
        }
        storeOldValues()
    }
    
    func decodeAngle3() {
        Rxy = (0.0...1.0).clamp(value: R1) // does this need clamping here? Will it ever be > 1.0?
        T1 = variableDiffLowPass(T1, lastoutput: T1_old, alpha: 0.5, LPdiff: 45.0, signalstrength:Rxy, LPgate: zoom(0.023622, y: R_zoom))
        Txy = T1 // do we need to differentiate between Txy and T1?
        Rxyz = (0.0...1.0).clamp(value: getMagnitude(Rxy, y: Z3)) // this one definitely needs clamping
        setThresholdZoom(thresholdZoom: 0.004, z_thresholdZoom: 0.004)
        
        if didCrossThreshold() {
            normaliseOutput() // re-scale Rxyz, Rxy, and Z3 values between 0 and 1 if necessary
            Tz = radToDegrees(atan2(Z3, Rxy))
            Rxyz = (0.0...1.0).clamp(value: getMagnitude(Rxy, y: Z3))
            findActiveZone(Tz: Tz)
        }
        else {
            resetAngleData()
        }
        storeOldValues()
    }
    // MARK: Decoding helper functions
    func setThresholdZoom(thresholdZoom: Double, z_thresholdZoom: Double) {
        self.thresholdZoom = thresholdZoom;
        self.z_thresholdZoom = z_thresholdZoom;
    }
    
    func didCrossThreshold()-> Bool {
        return Rxyz > thresholdZoom || Rxy > thresholdZoom || Z3 > z_thresholdZoom
    }
    
    func findActiveZone(Tz: Double) {
        param3 = 0.0
        param4 = 0.0
        
        if (Tz >= 90 - ZconeZ && Tz <= 90 + ZconeZ) {
            zone = .orange_side
            param4 = -((Tz - 90) / ZconeZ)
        }
        else {
            if Tz <= ZconeXY {
                if Txy >= 270 - XYcone && Txy <= 270 + XYcone {
                    zone = .blue_side
                    param3 = (Txy - 270) / XYcone
                }
                else if Txy > (180.0 + XYcone) && Txy < (270.0 - XYcone) {
                    zone = .red_blue
                    param3 = (Txy - redBlueAngle) / coneAngle
                }
                else if Txy >= 180 - XYcone && Txy <= 180 + XYcone {
                    zone = .red_side
                    param3 = (Txy - 180) / XYcone
                }
                else if Txy > (90 + XYcone) && Txy < (180 - XYcone) {
                    zone = .red_green
                    param3 = (Txy - redGreenAngle) / coneAngle
                }
                else if Txy >= 90 - XYcone && Txy <= 90 + XYcone {
                    zone = .green_side
                    param3 = (Txy-90)/XYcone
                }
                else if Txy > XYcone && Txy < (90 - XYcone) {
                    zone = .yellow_green
                    param3 = (Txy - yellowGreenAngle) / coneAngle
                }
                else if (Txy >= 0 && Txy <= XYcone) || Txy >= 360 - XYcone {
                    zone = .yellow_side
                    param3 = Txy > 360 - XYcone ? (Txy - 360) / XYcone : Txy / XYcone
                }
                else {
                    zone = .blue_yellow
                    param3 = (Txy - blueYellowAngle) / coneAngle
                }
                param4 = (Tz) / ZconeXY
            }
            else {
                if Txy >= 270 - XYcone && Txy <= 270 + XYcone {
                    zone = .orange_blue
                    param3 = (Txy-270) / XYcone
                }
                else if Txy > 180 + XYcone && Txy < 270 - XYcone {
                    zone = .orange_red_blue
                    param3 = (Txy - 180) / (90 - XYcone)
                }
                else if Txy >= 180 - XYcone && Txy <= 180 + XYcone {
                    zone = .orange_red
                    param3 = (Txy - 180) / XYcone
                }
                else if Txy > 90 + XYcone && Txy < 180 - XYcone {
                    zone = .orange_red_green
                    param3 = (Txy - 135) / (45 - XYcone)
                }
                else if Txy >= 90 - XYcone && Txy <= 90 + XYcone {
                    zone = .orange_green
                    param3 = (Txy - 90) / XYcone
                }
                else if (Txy > XYcone && Txy < 90 - XYcone) {
                    zone = .orange_yellow_green
                    param3 = (Txy - 45) / (45 - XYcone)
                }
                else if (Txy >= 0 && Txy <= XYcone) || Txy > 360 - XYcone {
                    zone = .orange_yellow
                    param3 = Txy > 360 - XYcone ? (Txy-360) / XYcone : (Txy) / XYcone
                }
                else {
                    zone = .orange_blue_yellow
                    param3 = (Txy-315) / (45-XYcone)
                }
                param4 = (Tz - ZconeXY) / (90-ZconeZ-ZconeXY) //90-ZconeZ-ZconeXY is the width of the remaining segement
            }
        }
    }
    
    func normaliseOutput() {
        if Rxyz > thresholdZoom {
            Rxyz = (Rxyz - thresholdZoom)/(1.0 - thresholdZoom) //normalise output after taking threshold into account
        }
        if Rxy > thresholdZoom {
            Rxy = (Rxy - thresholdZoom)/(1.0 - thresholdZoom) //normalise output after taking threshold into account
        }
        if Z3 > z_thresholdZoom {
            Z3 = (Z3 - z_thresholdZoom)/(1.0 - z_thresholdZoom) //normalise output after taking threshold into account
        }
    }
    
    func resetAngleData() {
        zone = .none
        Rxyz = 0.0
        Rxy = 0.0
        Z3 = 0.0
        ZC = 0.0    // only needed for firmware 0.0 decodeAngle()
        Tz = ZconeXY + 0.5 * (90 - ZconeZ - ZconeXY) //180 * atan2f(Z3, Rxy) / M_PI
        Txy = 180.0
    }
    
    func storeOldValues() {
        Rxyz_old = Rxyz
        Rxy_old = Rxy
        R1_old = R1
        R2_old = R2
        T1_old = T1
        T2_old = T2
        Tz_old = Tz
        Z3_old = Z3
    }
    
    // MARK: Route decoded signals back to the delegate
    func routeMono() {
        let zone1 : Int = activeZones[zone.rawValue][0].rawValue
        let lastZone1 : Int = activeZones[lastZone.rawValue][0].rawValue
        
        currenttime = NSDate()
        let deltaT = currenttime.timeIntervalSince(lasttime as Date)
        lasttime = currenttime
        // send shut up message(s)
        if (zone != lastZone && lastZone != .none) {  // don't repeatedly tell lastZone to shut up if he hasn't changed
            if lastZone1 != zone1 {
                if (lastZone1 != Zone.none.rawValue) {
                    flushSide(index:lastZone1)
                }
            }
        }
        
        switch (zone) {
        case .none:
            if lastZone != .none {
                for i in 0 ... 4 {
                    flushSide(index:i)
                }
            }
        case .red_side:
            red.rawValue = Rxy
        case .blue_side:
            blue.rawValue = Rxy
        case .yellow_side:
            yellow.rawValue = Rxy
        case .green_side:
            green.rawValue = Rxy
        case .orange_side:
            orange.rawValue = Rxyz
        default:
            break
        }
        var peak : Double?
        if zone1 != Zone.none.rawValue {
            if sides[zone1].rawValue >= sides[zone1].threshold {
                peak = sides[zone1].peak?.detect(input: sides[zone1].rawValue, dT: deltaT)
                sides[zone1].peakValue = peak
                sides[zone1].deltaT = deltaT
            }
            else {
                sides[zone1].peak?.reset()
                if threshRelease {
                    flushSide(index:zone1)
                    threshRelease = false
                }
            }
            
            sides[zone1].value = calculateResponse(amount: sides[zone1].response, input: sides[zone1].rawValue)
            delegate?.continuous(sides[zone1])
            if peak != nil {
                if (peak! > 0.0) {
                    delegate?.peak(sides[zone1],  calculateResponse(amount: sides[zone1].response, input: peak!))
                    threshRelease = true
                    sides[zone1].isPlaying = true
                }
            }
        }
        peak = nil
        lastZone = zone
    }
    
    func routeSignals() {
        let zone1 : Int = activeZones[zone.rawValue][0].rawValue
        let zone2 : Int = activeZones[zone.rawValue][1].rawValue
        let zone3 : Int = activeZones[zone.rawValue][2].rawValue
        
        let lastZone1 : Int = activeZones[lastZone.rawValue][0].rawValue
        let lastZone2 : Int = activeZones[lastZone.rawValue][1].rawValue
        let lastZone3 : Int = activeZones[lastZone.rawValue][2].rawValue
        
        currenttime = NSDate()
        let deltaT = currenttime.timeIntervalSince(lasttime as Date)
        lasttime = currenttime
        // send shut up message(s)
        if (zone != lastZone && lastZone != .none)
        {  // don't repeatedly tell lastZone to shut up if he hasn't changed
            if (lastZone1 != zone1 &&
                lastZone1 != zone2 &&
                lastZone1 != zone3)
            {
                if (lastZone1 != Zone.none.rawValue) {
                    flushSide(index:lastZone1)
                }
            }
            if (lastZone2 != zone1 &&
                lastZone2 != zone2 &&
                lastZone2 != zone3)
            {
                if (lastZone2 != Zone.none.rawValue) {
                    flushSide(index:lastZone2)
                }
            }
            if (lastZone3 != zone1 &&
                lastZone3 != zone2 &&
                lastZone3 != zone3)
            {
                if (lastZone3 != Zone.none.rawValue) {
                    flushSide(index:lastZone3)
                }
            }
        }
        
        bend_out = 1 - 0.5 * (param3 + 1.0)
        bend_in = 1 - bend_out
        
        let blend_in_xy = abs(sin(param3 * .pi / 2))
        let blend_out_xy = cos(param3 * .pi / 2)
        let blend_in_z = abs(sin(param4 * .pi / 2))
        
        let inputBlendOutXY = Rxy * blend_out_xy
        let inputBlendInXY = Rxy * blend_in_xy
        let inputBlendInZ = Rxyz * blend_in_z
        let inputBlendOutZ = Rxyz * blend_out_z
        let inputBlendOutXYZ = Rxyz * blend_out_z * blend_out_xy
        let inputBlendInXYZ = Rxyz * blend_out_z * blend_in_xy
        
        switch (zone) {
        case .none:
            if lastZone != .none {
                for i in 0 ... 4 {
                    if sides[i].isPlaying {
                        flushSide(index:i)
                    }
                }
            }
        case .red_side:
            red.rawValue = Rxy
        case .blue_side:
            blue.rawValue = Rxy
        case .yellow_side:
            yellow.rawValue = Rxy
        case .green_side:
            green.rawValue = Rxy
        case .orange_side:
            orange.rawValue = Rxyz
        default:
            if polyMode {
                switch (zone) {
                case .red_blue:
                    red.rawValue       = inputBlendOutXY
                    blue.rawValue      = inputBlendInXY
                case .blue_yellow:
                    blue.rawValue      = inputBlendOutXY
                    yellow.rawValue    = inputBlendInXY
                case .yellow_green:
                    yellow.rawValue    = inputBlendOutXY
                    green.rawValue     = inputBlendInXY
                case .red_green:
                    green.rawValue     = inputBlendOutXY
                    red.rawValue       = inputBlendInXY
                case .orange_red:
                    orange.rawValue    = inputBlendInZ
                    red.rawValue       = inputBlendOutZ
                case .orange_blue:
                    orange.rawValue    = inputBlendInZ
                    blue.rawValue      = inputBlendOutZ
                case .orange_yellow:
                    orange.rawValue    = inputBlendInZ
                    yellow.rawValue    = inputBlendOutZ
                case .orange_green:
                    orange.rawValue    = inputBlendInZ
                    green.rawValue     = inputBlendOutZ
                case .orange_red_blue:
                    orange.rawValue    = inputBlendInZ
                    red.rawValue       = inputBlendOutXYZ
                    blue.rawValue      = inputBlendInXYZ
                case .orange_blue_yellow:
                    orange.rawValue    = inputBlendInZ
                    blue.rawValue      = inputBlendOutXYZ
                    yellow.rawValue    = inputBlendInXYZ
                case .orange_yellow_green:
                    orange.rawValue    = inputBlendInZ
                    yellow.rawValue    = inputBlendOutXYZ
                    green.rawValue     = inputBlendInXYZ
                case .orange_red_green:
                    orange.rawValue    = inputBlendInZ
                    red.rawValue       = inputBlendOutXYZ
                    green.rawValue     = inputBlendInXYZ
                default: break
                }
            }
        }
        var peak : Double?
        if zone1 != Zone.none.rawValue {
            if sides[zone1].rawValue >= sides[zone1].threshold {
                peak = sides[zone1].peak?.detect(input: sides[zone1].rawValue, dT: deltaT)
            }
            else {
                flushSide(index:zone1)
            }
            
            sides[zone1].value = calculateResponse(amount: sides[zone1].response, input: sides[zone1].rawValue)
            
            delegate?.continuous(sides[zone1])
            if peak != nil {
                if (peak! > 0.0) {
                    delegate?.peak(sides[zone1], calculateResponse(amount: sides[zone1].response, input: peak!))
                    sides[zone1].isPlaying = true
                }
            }
        }
        peak = nil
        if zone2 != Zone.none.rawValue {
            if sides[zone2].rawValue >= sides[zone2].threshold {
                peak = sides[zone2].peak?.detect(input: sides[zone2].rawValue, dT: deltaT)
            }
            else {
                flushSide(index:zone2)
            }
            sides[zone2].value = calculateResponse(amount: sides[zone2].response, input: sides[zone2].rawValue)
            
            delegate?.continuous(sides[zone2])
            if peak != nil {
                if (peak! > 0.0) {
                    delegate?.peak(sides[zone2], calculateResponse(amount: sides[zone2].response, input: peak!))
                    sides[zone2].isPlaying = true
                }
            }
        }
        peak = nil
        if zone3 != Zone.none.rawValue {
            if sides[zone3].rawValue >= sides[zone3].threshold {
                peak  = sides[zone3].peak?.detect(input: sides[zone3].rawValue, dT: deltaT)
            }
            else {
                flushSide(index:zone3)
            }
            sides[zone3].value = calculateResponse(amount: sides[zone3].response, input: sides[zone3].rawValue)
            delegate?.continuous(sides[zone3])
            if peak != nil {
                if (peak! > 0.0) {
                    delegate?.peak(sides[zone3], calculateResponse(amount: sides[zone3].response, input: peak!))
                    sides[zone3].isPlaying = true
                }
            }
        }
        lastZone = zone
    }
    
    func routeSignals2() {
        let zone1 : Int = activeZones[zone.rawValue][0].rawValue
        let zone2 : Int = activeZones[zone.rawValue][1].rawValue
        let zone3 : Int = activeZones[zone.rawValue][2].rawValue
        
        let lastZone1 : Int = activeZones[lastZone.rawValue][0].rawValue
        let lastZone2 : Int = activeZones[lastZone.rawValue][1].rawValue
        let lastZone3 : Int = activeZones[lastZone.rawValue][2].rawValue
        
        currenttime = NSDate()
        let deltaT = currenttime.timeIntervalSince(lasttime as Date)
        lasttime = currenttime
        // send shut up message(s)
        if (zone != lastZone && lastZone != .none)
        {  // don't repeatedly tell lastZone to shut up if he hasn't changed
            if (lastZone1 != zone1 &&
                lastZone1 != zone2 &&
                lastZone1 != zone3)
            {
                if (lastZone1 != Zone.none.rawValue) {
                    flushSide(index:lastZone1)
                }
            }
            if (lastZone2 != zone1 &&
                lastZone2 != zone2 &&
                lastZone2 != zone3)
            {
                if (lastZone2 != Zone.none.rawValue) {
                    flushSide(index:lastZone2)
                }
            }
            if (lastZone3 != zone1 &&
                lastZone3 != zone2 &&
                lastZone3 != zone3)
            {
                if (lastZone3 != Zone.none.rawValue) {
                    flushSide(index:lastZone3)
                }
            }
        }
        
        bend_out = 1 - 0.5 * (param3 + 1.0)
        bend_in = 1 - bend_out
        
        let blend_in_xy = abs(sin(param3 * .pi / 2))
        let blend_out_xy = cos(param3 * .pi / 2)
        
        let inputBlendOutXY = Rxy * blend_out_xy
        let inputBlendInXY = Rxy * blend_in_xy
        
        switch (zone) {
        case .none:
            if lastZone != .none {
                for i in 0 ... 4 {
                    if sides[i].isPlaying {
                        flushSide(index:i)
                    }
                }
            }
        case .red_side:
            red.rawValue = Rxy
        case .blue_side:
            blue.rawValue = Rxy
        case .yellow_side:
            yellow.rawValue = Rxy
        case .green_side:
            green.rawValue = Rxy
        case .orange_side:
            orange.rawValue = Rxyz
        default:
            if polyMode {
                switch (zone) {
                case .red_blue:
                    red.rawValue       = inputBlendOutXY
                    blue.rawValue      = inputBlendInXY
                case .blue_yellow:
                    blue.rawValue      = inputBlendOutXY
                    yellow.rawValue    = inputBlendInXY
                case .yellow_green:
                    yellow.rawValue    = inputBlendOutXY
                    green.rawValue     = inputBlendInXY
                case .red_green:
                    green.rawValue     = inputBlendOutXY
                    red.rawValue       = inputBlendInXY
                case .orange_red:
                    orange.rawValue    = Z3
                    red.rawValue       = Rxy
                case .orange_blue:
                    orange.rawValue    = Z3
                    blue.rawValue      = Rxy
                case .orange_yellow:
                    orange.rawValue    = Z3
                    yellow.rawValue    = Rxy
                case .orange_green:
                    orange.rawValue    = Z3
                    green.rawValue     = Rxy
                case .orange_red_blue:
                    orange.rawValue    = Z3
                    red.rawValue       = inputBlendOutXY
                    blue.rawValue      = inputBlendInXY
                case .orange_blue_yellow:
                    orange.rawValue    = Z3
                    blue.rawValue      = inputBlendOutXY
                    yellow.rawValue    = inputBlendInXY
                case .orange_yellow_green:
                    orange.rawValue    = Z3
                    yellow.rawValue    = inputBlendOutXY
                    green.rawValue     = inputBlendInXY
                case .orange_red_green:
                    orange.rawValue    = Z3
                    red.rawValue       = inputBlendOutXY
                    green.rawValue     = inputBlendInXY
                default: break
                }
            }
        }
        if zone1 != Zone.none.rawValue {
            let peak = sides[zone1].peak?.detect(input: sides[zone1].rawValue, dT: deltaT)
            sides[zone1].value = calculateResponse(amount: sides[zone1].response, input: sides[zone1].rawValue)
            delegate?.continuous(sides[zone1])
            if peak != nil {
                if (peak! > 0.0) {
                    delegate?.peak(sides[zone1], calculateResponse(amount: sides[zone1].response, input: peak!))
                }
            }
        }
        if zone2 != Zone.none.rawValue {
            let peak = sides[zone2].peak?.detect(input: sides[zone2].rawValue, dT: deltaT)
            sides[zone2].value = calculateResponse(amount: sides[zone2].response, input: sides[zone2].rawValue)
            if peak != nil {
                if (peak! > 0.0) {
                    delegate?.peak(sides[zone2], calculateResponse(amount: sides[zone2].response, input: peak!))
                }
            }
            delegate?.continuous(sides[zone2])
        }
        if zone3 != Zone.none.rawValue {
            let peak = sides[zone3].peak?.detect(input: sides[zone3].rawValue, dT: deltaT)
            sides[zone3].value = calculateResponse(amount: sides[zone3].response, input: sides[zone3].rawValue)
            if peak != nil {
                if (peak! > 0.0) {
                    delegate?.peak(sides[zone3], calculateResponse(amount: sides[zone3].response, input: peak!))
                }
            }
            delegate?.continuous(sides[zone3])
        }
        lastZone = zone
    }
    
	// MARK: Helper Methods
    func print(_ object: Any) {
//        Swift.print(object)
    }

    public func flushSide(index:Int) {
        sides[index].rawValue = 0.0
        sides[index].value = 0.0
        sides[index].peak?.reset()
        delegate?.release(sides[index])
        delegate?.continuous(sides[index])
        sides[index].isPlaying = false
    }
}
