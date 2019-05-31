//
//  bluetoothMIDIConnect.swift
//  PlaygroundContent
//
//  Created by Developer Keith on 28/04/2017.
//  Copyright © 2017 Skoogmusic Ltd Inc. All rights reserved.
//

import Foundation
import CoreAudioKit


protocol BluetoothMIDIDelegate: class {
	func update(state: State)
    func bluetoothStopSearch()
    var state : State {get set}
    var skoogConnected : Bool {get set}
    func updateCell(width: CGFloat)
}

public class BluetoothMIDI : CABTMIDICentralViewController  {
    weak var delegate:BluetoothMIDIDelegate?
    public init() {
        super.init(nibName: nil, bundle: nil)
        // Do any additional setup after loading the view, typically from a nib.
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let initialCount = super.tableView(tableView, numberOfRowsInSection: section)

        guard let delegate = self.delegate else {
            return initialCount
        }
        
        var skoogCount = 0
        var skoogPresent = false
        for i in 0..<initialCount {
            let testCell = super.tableView(tableView, cellForRowAt: [section, i])
            for i in testCell.contentView.subviews {
                if let sv = i as? UILabel {
                    if sv.text == "Skoog" {
                        skoogPresent = true
                        delegate.updateCell(width: testCell.contentView.frame.size.width)
                    }
                }
            }
            if skoogPresent || delegate.skoogConnected  {
                skoogCount += 1
            }
        }
        if skoogCount > 0 {
            if delegate.skoogConnected == true {
                if delegate.state != .selecting && delegate.state != .connected {
                    delegate.update(state: .connected)
                }
            }
            else {
                if delegate.state != .connecting && delegate.state != .selecting {
                    delegate.update(state: .selecting)
                }
            }
        }
        else {
            if delegate.state == .selecting {
                delegate.update(state: .noConnection)
                delegate.bluetoothStopSearch()
            }
        }
        return initialCount
    }
    
    
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let testCell = super.tableView(tableView, cellForRowAt: indexPath)
        testCell.backgroundColor = .clear
        var skoogPresent = false
        
        for i in testCell.contentView.subviews.reversed() {
            if let sv = i as? UILabel {
                if sv.text == "Skoog" {
                    skoogPresent = true
                }
            }
            else {
                i.isHidden = true
            }
        }
        if skoogPresent { //Consider checking if detected skoog is online or offline here & hide if offline
            testCell.isHidden = false
        }
        else {
            testCell.isHidden = true
        }
        return testCell
    }

    
    
    
    open override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        return super.tableView(tableView, didDeselectRowAt: indexPath)
    }
    
    
    
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let delegate = self.delegate else {
            return super.tableView(tableView, didSelectRowAt: indexPath)
        }

        if delegate.skoogConnected == false {
            delegate.update(state: .connecting)
        }
        else {
            delegate.update(state: .disconnecting)
        }
        return super.tableView(tableView, didSelectRowAt: indexPath)
    }
    
    
    
    
    open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height = super.tableView(tableView, heightForHeaderInSection: section)
        height = 0.0
        return height
    }
    
    
    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = super.tableView(tableView, heightForRowAt: indexPath)
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        if cell.isHidden {
            height = 0.0
        }
        return height
    }
    
    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return ""
    }
    
    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    
}
