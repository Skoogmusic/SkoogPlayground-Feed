//
//  BLEMessages.swift
//  Bluetooth
//
//  Created by Keith Nagle on 27/09/2016.
//  Copyright © 2016 Skoogmusic Ltd. All rights reserved.
//
import Foundation
import UIKit
import CoreBluetooth

protocol bleMessagesDelegate: class {
    var skoogConnected : Bool {get set}
    var newConnection : Bool {get set}
    var connectedSkoog : CBPeripheral? {get set}
    var firmwareMajorVersion : Int {get set}
    var firmwareMinorVersion : Int {get set}
}

//let SKOOG_DEVICE_UUID       = "5027A2BB-3BDB-99FE-B1D3-6DDBD4BCD6A4"
let MIDI_SERVICE            = "03B80E5A-EDE8-4B33-A751-6CE34EC4C700" // MIDI Service
let MIDI_CHARACTERISTIC     = "7772E5DB-3868-4112-A1A9-F2669D106BF3" // MIDI Characteristic

let DEVICE_INFO_SERVICE_UUID  : CBUUID      = CBUUID.init(string: "0x180A")
let DEVICE_INFO_SERVICE_UUID_INT            = 0x180A
let DEVICE_FIRMWARE_REVISION_UUID  : CBUUID = CBUUID.init(string: "0x2A26")
let DEVICE_FIRMWARE_REVISION_UUID_INT       = 0x2A26
let BATTERY_LEVEL_SERVICE_READ_LEN          = 1
let BATTERY_CHARACTERISTIC_UUID : CBUUID    = CBUUID.init(string: "0x180F")
let BATTERY_CHARACTERISTIC_UUID_INT         = 0x180F
let BATTERY_LEVEL_SERVICE_UUID  : CBUUID    = CBUUID.init(string: "0x2A19")
let BATTERY_LEVEL_SERVICE_UUID_INT          = 0x2A19

public class BLEMessages: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    weak var delegate:bleMessagesDelegate?
    
    var centralManager: CBCentralManager?
    var discoveredPeripheral: CBPeripheral?
    var midiCharacteristic : CBCharacteristic?
    var skoogCount : Int = 0
    var batteryLevel : Int = 0
    var firmwareRevisionString : String = ""
    
    var firmwareMajorVersion : Int = -1
    var firmwareMinorVersion : Int = -1
    var firmwareServiceAdvertisedFlag : Bool = false
    
    var rangeValue : Int = 1
    
    // And somewhere to store the incoming data
    fileprivate let data = NSMutableData()
    
    override init() {
        super.init()
        // Start up the CBCentralManager
        centralManager = CBCentralManager(delegate: self, queue: nil)
        batteryLevel = 0
    }
    // MARK: - peripheral methods
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Peripheral didDiscoverServices \(peripheral.services!.count)")
        // Always start with this flag false, in case we disconnect from the new
        // firmware and then connect to the old firmware. Unlikely, but certainly happens regularly during testing.
        firmwareServiceAdvertisedFlag = false
        self.firmwareMajorVersion = -1
        self.delegate?.firmwareMajorVersion = -1
        self.firmwareMinorVersion = -1
        self.delegate?.firmwareMinorVersion = -1
        
        for i in peripheral.services! {
            if i.uuid == DEVICE_INFO_SERVICE_UUID {
                firmwareServiceAdvertisedFlag = true
            }
            peripheral.discoverCharacteristics(nil, for: i)
        }
        
        // after looking at everything, if there was no firmare version stuff present, then we are firmware 0 0
        if !firmwareServiceAdvertisedFlag {
            //            print("SETTING OLD FIRMWARE!!!!!!!!")
            self.firmwareMajorVersion = 0
            self.delegate?.firmwareMajorVersion = 0
            self.firmwareMinorVersion = 0
            self.delegate?.firmwareMinorVersion = 0
        }
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        let midiCharacteristicUUID : CBUUID  = CBUUID.init(string: MIDI_CHARACTERISTIC)
        
        for i in service.characteristics! {
            // we know that the MIDI service has only one characteristic
            // so we focus directly on that. Assuming it's the  MIDI characteristic
            if i.uuid.uuidString == midiCharacteristicUUID.uuidString {
                // All good, let's set a local copy of the MIDI characteristic
                self.midiCharacteristic = i;
                
                // Note: ideally we would like to establish that a Skoog is connected and store all of
                // its details in self.delegate.connectedSkoog and self.midiCharacteristic
                // so that any time we want to send a calibrate message we just call the method [self calibrate]
                // The only problem with this is that we are not responsible for connecting the Skoog
                // It could have connected through GarageBand, or at any time during the App's life cycle
                // The best we can do now is attempt a local connection to the Skoog when we want to
                // calibrate. After we've calibrated, we can disconnect and reset all the variables
                // So that if we disconnect through other means, a [self calibrate] method call doesn't
                // cause a crash.
                // This may seem a bit wasteful and repetitive for now, but it's the best we can do given
                // The short timescales.
            }
            else if i.uuid == BATTERY_LEVEL_SERVICE_UUID {
                peripheral.readValue(for: i)
            }
            else if i.uuid == DEVICE_FIRMWARE_REVISION_UUID {
                //                firmwareServiceAdvertisedFlag = true
                peripheral.readValue(for: i)
            }
        }
    }
    
    // This callback lets us know more data has arrived via notification on the characteristic
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            switch characteristic.uuid {
            case BATTERY_LEVEL_SERVICE_UUID:
                var batlevel : UInt8 = 0
                characteristic.value?.copyBytes(to: &batlevel, count: BATTERY_LEVEL_SERVICE_READ_LEN)
                self.batteryLevel = Int(batlevel)
                break
            case DEVICE_FIRMWARE_REVISION_UUID:
                guard let data = characteristic.value else { return }
                //                var buffer : [UInt8] = [0, 0, 0]
                var buffer = [UInt8](data)
                let tempstring : [Character] = [Character(UnicodeScalar(buffer[0])),  Character(UnicodeScalar(buffer[1])), Character(UnicodeScalar(buffer[2]))]
                self.firmwareRevisionString = String(tempstring)
                for (index, i ) in self.firmwareRevisionString.enumerated() {
                    if index == 0 {
                        self.firmwareMajorVersion = Int(String(i))!
                        self.delegate?.firmwareMajorVersion = Int(String(i))!
                    }
                    if index == 2 {
                        self.firmwareMinorVersion = Int(String(i))!
                        self.delegate?.firmwareMinorVersion = Int(String(i))!
                    }
                }
                print("FirmwareRevisionString is: \(self.firmwareRevisionString), \(self.firmwareMajorVersion) \(self.firmwareMinorVersion)")
            default:
                break
            }
        }
        else {
            // not in use
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // not in use
        
    }
    
    // MARK: - centralManager methods
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // not in use
    }
   
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
// This only seems to happen if we get disconnected through a standby message
// print("The skoog was disconnected by the centralManager:  Peripheral: \(peripheral) : Error Status: \(error)")
        if error == nil {
            self.delegate?.newConnection = true
            //            self.delegate?.skoogConnected = false
            //            print("set skoogConnected = false 1")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // not in use
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // not in use
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//  "DID CONNECT PERIPHERAL CALLED!
        if peripheral.name == "Skoog" && peripheral.state == .connected {
//       "DID CONNECT SKOOG!
            self.delegate?.connectedSkoog?.discoverServices(nil)
            self.delegate?.skoogConnected = true
        }
    }
    
// MARK: - local helper methods
    public func findSkoog(shouldConnect: Bool){
        // This is the entry point of the system
        // we first look for a connected device with a MIDI service
        // So, we need to pass a CBUUID object
//      "Searching for Skoogs now..."
        let midiServiceUUID : CBUUID  = CBUUID.init(string: MIDI_SERVICE)
        // Did we find any connected peripherals with the MIDI service?
        if ((self.centralManager?.retrieveConnectedPeripherals(withServices: [midiServiceUUID])) != nil) {
            self.skoogCount = 0;
            for i in 0 ..< (self.centralManager?.retrieveConnectedPeripherals(withServices: [midiServiceUUID]).count)! {
                // set up a temporary peripheral to reference the first device found. It may not be a Skoog.
                let local : CBPeripheral = (self.centralManager?.retrieveConnectedPeripherals(withServices: [midiServiceUUID])[i])!
                // did we get anything back?
                // Is it a Skoog?
                if !(local.name?.range(of: "Skoog")?.isEmpty)! {
                    self.skoogCount = 1
                    // We can now say our delegate.connectedSkoog is the one we found
                    self.delegate?.connectedSkoog = local
                    self.delegate?.connectedSkoog?.delegate = self // we are the delegate, the peripheral will use our delegate methods
                    if shouldConnect {
                        // make a local connection to the peripheral
                        self.centralManager?.connect(self.delegate!.connectedSkoog!, options: nil)
//                        [self.CM connectPeripheral: self.delegate.connectedSkoog options:[NSDictionary dictionaryWithObject:CBConnectPeripheralOptionNotifyOnDisconnectionKey forKey:@"Disconnected"]];
                        // discover its services... this will trigger the callback "peripheral didDiscoverServices"
                        break
                    }
                    else {
                        self.centralManager?.connect(self.delegate!.connectedSkoog!, options: nil)
//                        [self.CM connectPeripheral: self.delegate.connectedSkoog options:[NSDictionary dictionaryWithObject:CBConnectPeripheralOptionNotifyOnDisconnectionKey forKey:@"Disconnected"]];
                
//                 "NOT Connecting Skoog with connection state: \(self.delegate?.connectedSkoog?.state)"
                    }
                }
            }
            
            if self.skoogCount < 1 {
//              "No Skoogs connected!"
                self.delegate?.skoogConnected = false
            }
        }
        else {
//           "No MIDI device connected!"
            self.delegate?.skoogConnected = false
            //            print("set skoogConnected = false 3")
            
        }
    }
    
//    public func setDefaults() {
//        
//        switch defaults.integer(forKey: "ScaleMode") {
//        case 0:
//            self.rangeValue = 0xA0
//            break
//        case 1:
//            self.rangeValue = 0xA1
//            break
//        case 2:
//            self.rangeValue = 0xA2
//            break
//        default:
//            // let's get out of here
//            break
//        }
//        changeSensitivityRange()
//        
//        switch defaults.integer(forKey: "ZScaleMode") {
//        case 0:
//            self.rangeValue = 0x90
//            break
//        case 1:
//            self.rangeValue = 0x91
//            break
//        case 2:
//            self.rangeValue = 0x92
//            break
//        default:
//            // let's get out of here
//            break
//        }
//        changeSensitivityRange()
//        
//        switch defaults.integer(forKey: "FilterMode") {
//        case 0:
//            self.rangeValue = 0xB0
//            break
//        case 1:
//            self.rangeValue = 0xB1
//            break
//        case 2:
//            self.rangeValue = 0xB2
//            break
//        default:
//            // let's get out of here
//            break
//        }
//        changeSensitivityRange()
//        
//        switch defaults.integer(forKey: "FloorMode") {
//        case 0:
//            self.rangeValue = 0xF0
//            break
//        case 1:
//            self.rangeValue = 0xF1
//            break
//        case 2:
//            self.rangeValue = 0xF2
//            break
//        default:
//            // let's get out of here
//            break
//        }
//        changeSensitivityRange()
//        
//        switch defaults.integer(forKey: "OutputMode") {
//        case 0:
//            self.rangeValue = 0xC0
//            break
//        case 1:
//            self.rangeValue = 0xC1
//            break
//        case 2:
//            self.rangeValue = 0xC2
//            break
//        default:
//            // let's get out of here
//            break
//        }
//        changeSensitivityRange()
//    }
    
    public func changeSensitivityRange() {
        // Here we are going to adjust the scale, filter or output modes
        // 0xA0, 0xA1, 0xA2, 0xB0, 0xB1, 0xB2, 0xC0, 0xC1, 0xC2
        //        print("Writing value : \(self.rangeValue)")
        let value : UInt8  = UInt8(self.rangeValue)
        
        let data : Data = Data.init(bytes: [value])
        
        if ((self.delegate?.connectedSkoog) != nil) {
            if (self.midiCharacteristic != nil) {
                
                self.delegate?.connectedSkoog?.writeValue(data, for: self.midiCharacteristic!, type: .withoutResponse)
                self.disconnect()
            }
        }
    }
    
    public func calibrate() {
//      "Calibrate being called"
        // This is where we send the message through to the writeValue method of the peripheral
        let i : UInt8  = 0x01
        let d : Data = Data.init(bytes: [i])
        if ((self.delegate?.connectedSkoog) != nil) {
            if (self.midiCharacteristic != nil) {
//              "calibrate message being executed"
                self.delegate?.connectedSkoog?.writeValue(d, for: self.midiCharacteristic!, type: .withoutResponse)
                self.disconnect()
            }
        }
    }
    
    public func disconnect() {
        if (self.delegate?.skoogConnected)! {
            if ((self.delegate?.connectedSkoog) != nil) {
                self.centralManager?.cancelPeripheralConnection((self.delegate?.connectedSkoog)!)
            }
            self.delegate?.connectedSkoog = nil
            self.midiCharacteristic = nil
        }
    }
    
    public func readBattery (p : CBPeripheral) {
        self.readValue(serviceUUID: BATTERY_CHARACTERISTIC_UUID_INT, characteristicUUID: BATTERY_LEVEL_SERVICE_UUID_INT, p: p)
    }
    
    public func readValue (serviceUUID: Int, characteristicUUID: Int,  p:CBPeripheral) {

        let s : UInt16 = UInt16(serviceUUID)
        let c : UInt16 = UInt16(characteristicUUID)
        
        let s1 : UInt8 = UInt8(s >> 8)
        let s2 : UInt8 = UInt8(s & 0x00ff)
        let array1 : [UInt8] = [s1, s2]
        
        let c1 : UInt8 = UInt8(c >> 8)
        let c2 : UInt8 = UInt8(c & 0x00ff)
        let array2 : [UInt8] = [c1, c2]
        
        let sd : Data = Data.init(bytes: array1)
        let cd : Data = Data.init(bytes: array2)
        let su : CBUUID = CBUUID.init(data: sd)
        let cu : CBUUID = CBUUID.init(data: cd)

        let service : CBService? = findServiceFromUUID(UUID: su, p: p)
        if service == nil {
            //Could not find service with UUID %s on peripheral with UUID
            return
        }

        let characteristic : CBCharacteristic? = findCharacteristicFromUUID(UUID: cu, service:service!)!
        if characteristic == nil {
//            Could not find characteristic with UUID %s on service with UUID
            return
        }
        p.readValue(for: characteristic!)
    }
    
    /**
     *  @method findServiceFromUUID:
     *
     *  @param UUID CBUUID to find in service list
     *  @param p Peripheral to find service on
     *
     *  @return pointer to CBService if found, nil if not
     *
     *  @discussion findServiceFromUUID searches through the services list of a peripheral to find a
     *  service with a specific UUID
     *
     */
    public func findServiceFromUUID(UUID: CBUUID, p: CBPeripheral)->CBService? {
        
        for i in 0 ..< (p.services?.count)! {
            let s : CBService = p.services![i]
            print("s.uuid: \(s.uuid) UUID: \(UUID)")
            if compareCBUUID(UUID1: s.uuid, UUID2: UUID){
                return s
            }
        }
        return nil //Service not found on this peripheral
    }
    
    public func compareCBUUID(UUID1 : CBUUID,  UUID2 : CBUUID)->Bool{
        var b1 : [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        var b2 : [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        UUID1.data.copyBytes(to: &b1, count: 16)
        UUID2.data.copyBytes(to: &b2, count: 16)
        if b1 == b2 {
            return true
        }
        else {
            return false
        }
    }
    
    public func findCharacteristicFromUUID(UUID : CBUUID, service : CBService)->CBCharacteristic?{
        if service.characteristics != nil {
            for i in 0 ..< (service.characteristics?.count)! {
                let c : CBCharacteristic = service.characteristics![i]
                if compareCBUUID(UUID1: c.uuid,  UUID2:UUID) {
                    return c
                }
            }
        }
        return nil //Characteristic not found on this service
    }
    
    fileprivate func cancelPeripheralConnection() {
        // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
        centralManager?.cancelPeripheralConnection(discoveredPeripheral!)
    }
}
