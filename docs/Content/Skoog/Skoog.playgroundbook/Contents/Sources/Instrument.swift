
//
//  Instrument.swift
//
//  Created by David Skulina on 27/09/2016.
//  Copyright © 2017 Skoogmusic Ltd. All rights reserved.
//
//   A Core Audio MIDISynth with Filter and Reverb Effects.
//	 This will add a polyphonic `kAudioUnitSubType_MIDISynth` audio unit to the `AUGraph`.///
// - Some parts written by Gene De Lisa
// - copyright: 2016 Gene De Lisa
// - date: February 2016

import Foundation
import AudioToolbox
import CoreAudio

public enum SoundStyle {
    case fmModulator
    case solarWind
    case candyBee
    case acid
    case gamelan
    case strat
    case rhodes
    case jharp
    case marimba
    case rect
    case sqr
    case saw
    case ocarina
    case minimogo
    case noise
    case elecpiano
	case afromallet
	case nylonguitar
	case vibraphone
	case timpani
    public var string: String {
        switch self {
        case .fmModulator:
            return "Soundfonts/FM Modulator"
        case .solarWind:
            return "Soundfonts/Solar Wind"
        case .candyBee:
            return "Soundfonts/Candy Bee"
        case .acid:
            return "Soundfonts/Acid"
        case .gamelan:
            return "Soundfonts/Gamelan"
        case .strat:
            return "Soundfonts/Strat"
        case .rhodes:
            return "Soundfonts/Electrhode"
        case .jharp:
            return "Soundfonts/Jharp"
        case .marimba:
            return "Soundfonts/Marimba"
        case .rect:
            return "Soundfonts/Rect"
        case .sqr:
            return "Soundfonts/Sqr"
        case .saw:
            return "Soundfonts/Saw"
        case .ocarina:
            return "Soundfonts/Ocarina"
        case .minimogo:
            return "Soundfonts/MiniMogo"
        case .noise:
            return "Soundfonts/Noise"
        case .elecpiano:
            return "Soundfonts/ElecPiano"
		case .afromallet:
			return "Soundfonts/AfroMallet"
		case .nylonguitar:
				return "Soundfonts/NylonGuitar"
		case .vibraphone:
			return "Soundfonts/Vibraphone"
		case .timpani:
			return "Soundfonts/Timpani"
        }
    }
    public var description: String {
        switch self {
        case .fmModulator:
            return "FM Modulator"
        case .solarWind:
            return "Solar Wind"
        case .candyBee:
            return "Candy Bee"
        case .acid:
            return "Acid"
        case .gamelan:
            return "Gamelan"
        case .strat:
            return "Strat"
        case .rhodes:
            return "Electrhode"
        case .jharp:
            return "Jharp"
        case .marimba:
            return "Marimba"
        case .rect:
            return "Rect"
        case .sqr:
            return "Sqr"
        case .saw:
            return "Saw"
        case .ocarina:
            return "Ocarina"
        case .minimogo:
            return "MiniMogo"
        case .noise:
            return "Noise"
        case .elecpiano:
            return "ElecPiano"
        case .afromallet:
            return "AfroMallet"
        case .nylonguitar:
            return "NylonGuitar"
        case .vibraphone:
            return "Vibraphone"
        case .timpani:
            return "Timpani"
        }
    }
}

public class Instrument : NSObject {
    
    var outGraph		: AUGraph?
    var midisynthUnit   : AudioUnit?
    var effectUnit      : AudioUnit?
    var reverbUnit      : AudioUnit?
    var mixerUnit       : AudioUnit?
    var ioUnit          : AudioUnit?
	var midisynthNode   = AUNode()
	var effectNode      = AUNode()
	var reverbNode      = AUNode()
	var mixerNode       = AUNode()
	var ioNode          = AUNode()
    var noteOnArray     = [[UInt32]]() // initialise blank array
    var isPlaying:Bool
    
    let patch1          = UInt32(12)

    public var type: SoundStyle = .vibraphone
    
    /// Initialize.
    /// set up the graph, load a sound font into the synth and start the graph.
    public override init() {
        self.outGraph	= nil
        self.midisynthUnit		= nil
        self.ioUnit				= nil
        self.effectUnit			= nil
        self.reverbUnit			= nil
        self.mixerUnit			= nil

        self.isPlaying			= false
        super.init()
        
        augraphSetup()
        loadPatches()
        startGraph()
    }
    
    
/////////////////////////////////////////////////////////////////////////
// MARK: - AudioUnit methods
/////////////////////////////////////////////////////////////////////////
    
    /// Create the `AUGraph`, the nodes and units, then wire them together.
    func augraphSetup() {
        
        NewAUGraph(&outGraph)
        
        createIONode()
        createSynthNode()
        createEffectNode()
        createReverbNode()

        // now do the wiring. The graph needs to be open before you call AUGraphNodeInfo
        AUGraphOpen(self.outGraph!)
        AUGraphNodeInfo(self.outGraph!, self.midisynthNode, nil, &midisynthUnit)
        AUGraphNodeInfo(self.outGraph!, self.ioNode, nil, &ioUnit)
        AUGraphNodeInfo(self.outGraph!, self.effectNode, nil, &effectUnit)
        AUGraphNodeInfo(self.outGraph!, self.reverbNode, nil, &reverbUnit)

        AUGraphConnectNodeInput(self.outGraph!,
                                self.midisynthNode, 0,	// srcnode, SourceOutputNumber
                                self.effectNode,	0)		// destnode, DestInputNumber
        
        AUGraphConnectNodeInput(self.outGraph!,
                                self.effectNode, 0,		// srcnode, SourceOutputNumber
                                self.reverbNode, 0)		// destnode, DestInputNumber
        
        AUGraphConnectNodeInput(self.outGraph!,
                                self.reverbNode, 0,		// srcnode, SourceOutputNumber
                                self.ioNode, 0)			// destnode, DestInputNumber
		
        initReverb()
        initLowPass()
    }

    
    /// Create the Output Node and add it to the `AUGraph`.
    func createIONode() {
        var cd = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Output),
            componentSubType: OSType(kAudioUnitSubType_RemoteIO),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,componentFlagsMask: 0)
        AUGraphAddNode(self.outGraph!, &cd, &ioNode)
    }
    
    /// Create the Synth Node and add it to the `AUGraph`.
    func createSynthNode() {
        var cd = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_MusicDevice),
            componentSubType: OSType(kAudioUnitSubType_MIDISynth),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,componentFlagsMask: 0)
        AUGraphAddNode(self.outGraph!, &cd, &midisynthNode)
    }
    
    
    /// This will load the default sound font and set the synth unit's property.
    /// - postcondition: `self.midisynthUnit` will have it's sound font url set.
    public func loadSoundStyle(type: SoundStyle)  {
        if var bankURL = Bundle.main.url(forResource: type.string, withExtension: "sf2")  {
            AudioUnitSetProperty(
                self.midisynthUnit!,
                AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
                AudioUnitScope(kAudioUnitScope_Global),
                0,
                &bankURL,
                UInt32(MemoryLayout<URL>.size))
        }
    }
    
    
    /// Pre-load the patches you will use.
    ///
    /// Turn on `kAUMIDISynthProperty_EnablePreload` so the midisynth will load the patch data from the file into memory.
    /// You load the patches first before playing a sequence or sending messages.
    /// Then you turn `kAUMIDISynthProperty_EnablePreload` off. It is now in a state where it will respond to MIDI program
    /// change messages and switch to the already cached instrument data.
    ///
    /// - precondition: the graph must be initialized
    func loadPatches() {
        
        var enabled = UInt32(1)
        
        AudioUnitSetProperty(
            self.midisynthUnit!,
            AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &enabled,
            UInt32(MemoryLayout<UInt32>.size))
        
        for n : UInt32 in 0...4 {
            let pcCommand = UInt32(0xC0 | n) //patch change event
            MusicDeviceMIDIEvent(self.midisynthUnit!, pcCommand, patch1, 0, n)
        }
        
        enabled = UInt32(0)
        AudioUnitSetProperty(
            self.midisynthUnit!,
            AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &enabled,
            UInt32(MemoryLayout<UInt32>.size))
        
        // at this point the patches are loaded. You still have to send a program change at "play time" for the synth
        // to switch to that patch
    }
    
    
    /// Starts the `AUGraph`
    func startGraph() {
        var outIsInitialized = DarwinBoolean(false)
        AUGraphIsInitialized(self.outGraph!, &outIsInitialized)
        AUGraphInitialize(self.outGraph!)
        
        var isRunning = DarwinBoolean(false)
        AUGraphIsRunning(self.outGraph!, &isRunning)
        
        AUGraphStart(self.outGraph!)
        
        self.isPlaying = true
    }
    
    func stopGraph() {
        AUGraphStop(self.outGraph!)
        self.isPlaying = false
        augraphSetup()
        loadPatches()
    }
    
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Reverb methods
/////////////////////////////////////////////////////////////////////////
    
    // Create the Reverb Node and add it to the `AUGraph`.
    func createReverbNode() {
        var cd = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Effect),
            componentSubType: OSType(kAudioUnitSubType_Reverb2),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,componentFlagsMask: 0)
        AUGraphAddNode(self.outGraph!, &cd, &reverbNode)
    }
    
    
    func initReverb(){
        // Global, CrossFade, 0->100, 100
        AudioUnitSetParameter(self.reverbUnit!, kAudioUnitScope_Global, 0, kReverb2Param_DryWetMix, 50.0, 0)
        
        // Global, Decibels, -20->20, 0
        AudioUnitSetParameter(self.reverbUnit!, kAudioUnitScope_Global, 0, kReverb2Param_Gain, 1, 0)
        
        // Global, Secs, 0.0001->1.0, 0.008
        AudioUnitSetParameter(self.reverbUnit!, kAudioUnitScope_Global, 0, kReverb2Param_MinDelayTime, 0.008, 0)
        
        // Global, Secs, 0.0001->1.0, 0.050
        AudioUnitSetParameter(self.reverbUnit!, kAudioUnitScope_Global, 0, kReverb2Param_MaxDelayTime, 0.05, 0)
        
        // Global, Secs, 0.001->20.0, 1.0
        AudioUnitSetParameter(self.reverbUnit!, kAudioUnitScope_Global, 0, kReverb2Param_DecayTimeAt0Hz, 1.0, 0)
    
        // Global, Secs, 0.001->20.0, 0.5
        AudioUnitSetParameter(self.reverbUnit!, kAudioUnitScope_Global, 0, kReverb2Param_DecayTimeAtNyquist, 5.0, 0)
        
        // Global, Integer, 1->1000
        AudioUnitSetParameter(self.reverbUnit!, kAudioUnitScope_Global, 0, kReverb2Param_RandomizeReflections, 6, 0)
    }
    
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Filter methods
/////////////////////////////////////////////////////////////////////////
    
    
    // Create the Effect Node and add it to the `AUGraph`.
    func createEffectNode() {
        // try k​Audio​Unit​Sub​Type_NBand​EQ
        // with parameter: k​AUNBand​EQParam_Filter​Type set to
        // k​AUNBand​EQFilter​Type_2nd​Order​Butterworth​Low​Pass or
        // k​AUNBand​EQFilter​Type_Resonant​Low​Pass
        
        var cd = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Effect),
            componentSubType: OSType(kAudioUnitSubType_LowPassFilter),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,componentFlagsMask: 0)
        AUGraphAddNode(self.outGraph!, &cd, &effectNode)
    }

    
    func initLowPass(){
        /// Cutoff Frequency (Hz) ranges from 10 to 22050 (Default: 6900)
        AudioUnitSetParameter(self.effectUnit!, kAudioUnitScope_Global, 0, kLowPassParam_CutoffFrequency, 20000, 0)
		
        /// Resonance (dB) ranges from -20 to 40 (Default: 0)
        AudioUnitSetParameter(self.effectUnit!, kAudioUnitScope_Global, 0, kLowPassParam_Resonance, 10, 0)
        }

    
    public func filterCutOff(frequency: Double){
		//TODO: avoid glitches by ramping values... try AudioUnitParameterEvent  and
		//func AudioUnitScheduleParameters(_ inUnit: AudioUnit,
		//                                 _ inParameterEvent: UnsafePointer<AudioUnitParameterEvent>,
		//                                 _ inNumParamEvents: UInt32) -> OSStatus
		
        /// Cutoff Frequency (Hz) ranges from 10 to 22050 (Default: 6900)
        let cutoff = (10.0...22050.0).clamp(value: frequency)
        AudioUnitSetParameter(self.effectUnit!, kAudioUnitScope_Global, 0, kLowPassParam_CutoffFrequency, Float(cutoff), 0)
    }
    
    public func filterResonance(resonance: Double){
        //TODO: avoid glitches by ramping values... try AudioUnitParameterEvent  and
        //func AudioUnitScheduleParameters(_ inUnit: AudioUnit,
        //                                 _ inParameterEvent: UnsafePointer<AudioUnitParameterEvent>,
        //                                 _ inNumParamEvents: UInt32) -> OSStatus
        
        /// Resonance (dB) ranges from -20 to 40 (Default: 0)
        let resonance = (-20.0...40.0).clamp(value: resonance)
        AudioUnitSetParameter(self.effectUnit!, kAudioUnitScope_Global, 0, kLowPassParam_Resonance, Float(resonance), 0)
    }
    
    
    
/////////////////////////////////////////////////////////////////////////
// MARK: - MIDI methods
/////////////////////////////////////////////////////////////////////////
    
    public func noteOn(noteNum:MidiNoteNumber, velocity: MidiVelocity, channel: MidiChannel)    {
        // note on command
        let noteCommand = UInt32(0x90 | channel)
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, UInt32(noteNum), UInt32(velocity), UInt32(channel))
	}
	
    
    public func noteOff(noteNum:MidiNoteNumber, channel: MidiChannel)    {
        // note off command
        let noteCommand = UInt32(0x80 | channel)
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, UInt32(noteNum), 0, 0)
    }

	
	public func channelPressure(pressure:Int, channel: MidiChannel)    {
        // channel pressure command
        let noteCommand = UInt32(0xA0 | channel)
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, UInt32(pressure), 0, UInt32(channel))
    }
	
	public func afterTouch(note: MidiNoteNumber, touch:Int, channel: MidiChannel)    {
		// aftertouch command
		let noteCommand = UInt32(0xA0 | channel)
		MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, UInt32(note), UInt32(touch), UInt32(channel))
	}
	
    public func pitchBend(bend:Int, channel: MidiChannel)    {
        // pitchbend command
        let lsb = UInt8(bend & 0xFF)
        let msb = UInt8((bend >> 7) & 0xFF)
        let noteCommand = UInt32(0xE0 | channel)
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, UInt32(lsb), UInt32(msb), UInt32(channel))
    }
    
    public func pitchRange(range:Int, channel: MidiChannel){
        let noteCommand = UInt32(0xB0 | channel)
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, 101, 0, UInt32(channel))
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, 100, 0, UInt32(channel))
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, 6, UInt32(range), UInt32(channel))
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, 38, 0, UInt32(channel))
    }
    
    public func volume(value:Int, channel: MidiChannel)    {
        // volume change command
        let noteCommand = UInt32(0xB0 | channel)
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, 7, UInt32(value), UInt32(channel))
    }
    
    public func modulate(value:Int, channel: MidiChannel)    {
        // volume change command
        let noteCommand = UInt32(0xB0 | channel)
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, 1, UInt32(value), UInt32(channel))
    }
    
    public func expression(value:Int, channel: MidiChannel)    {
        // volume change command
        let noteCommand = UInt32(0xB0 | channel)
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, 11, UInt32(value), UInt32(channel))
    }
    
    public func pan(value:Int, channel: MidiChannel)    {
        // volume change command
        let noteCommand = UInt32(0xB0 | channel)
        MusicDeviceMIDIEvent(self.midisynthUnit!, noteCommand, 10, UInt32(value), UInt32(channel))
    }
}
