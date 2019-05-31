import UIKit
import PlaygroundSupport
import CoreBluetooth

public enum State : Int {
    case noConnection = 0
    case connecting
    case searching
    case selecting
    case connected
    case disconnecting
    case uninitialised
}

public protocol BTUIDelegate: class {
    func refreshUI()
}



public class BluetoothMIDIViewController : UIViewController, BluetoothMIDIDelegate, CBPeripheralManagerDelegate {
    
    public weak var delegate:BTUIDelegate?
    var myBTManager : CBPeripheralManager?
    public var skoogConnected = false
    let containerView		= UIView()
    var bluetoothMIDIViewController : BluetoothMIDI? = nil
    public var button = ConnectionButton(type: .system) as UIButton
    var label = UILabel()
    var state : State = .uninitialised
    var loadingImage = UIImage(named: "swiftLoading")?.withRenderingMode(.alwaysOriginal)

	
	public var labelHeightConstraint  = NSLayoutConstraint()
	public var containerHeightConstraint = NSLayoutConstraint()
	public var viewHeightConstraint = NSLayoutConstraint()
	public var viewWidthConstraint = NSLayoutConstraint()
    
    var searchTimer : Timer?
	
	public var cornerRadius : CGFloat = 22
	
    override open func viewDidLoad() {
        super.viewDidLoad()

        self.view.frame = CGRect(x: 0, y: 44, width: 240, height: 256)
        let frameHeight = CGFloat(44.0)
        self.cornerRadius = CGFloat(frameHeight / 2.0)
        
        self.navigationController?.title = NSLocalizedString("Connect Skoog", comment: "connect Skoog text")
        self.navigationController?.isNavigationBarHidden = false
        
        self.view.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
        self.view.isUserInteractionEnabled = true
        self.view.layer.cornerRadius = cornerRadius
        
        label.text = NSLocalizedString("Select Skoog", comment: "bluetooth midi label text")
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.frame = CGRect(x: 0.0, y: 0.0, width: 240, height: frameHeight)
        label.textAlignment = .center
        self.view.addSubview(label)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("Skoog", comment: "Skoog text"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20.0, weight: UIFont.Weight.regular)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 240, height: frameHeight)
        
        button.imageView?.backgroundColor = .clear
        button.layer.cornerRadius = cornerRadius
        button.backgroundColor = .clear
        button.tintColor = swiftRed
        
        button.addTarget(self, action: #selector(buttonCallback), for: .touchUpInside)

        self.view.addSubview(button)
        
		containerView.frame		=	CGRect(x:		0,
										   y:		44,
										   width:	240,
										   height:	256 - 88)
        
		
        self.view.addSubview(containerView)

		containerView.translatesAutoresizingMaskIntoConstraints = false
		containerView.clipsToBounds = true
        
		
/////////////////////////////////////////////////////////////////////////
// MARK: - Initialise constraints
/////////////////////////////////////////////////////////////////////////
		
        let labelTopConstraint = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
//        labelTopConstraint.priority = UILayoutPriorityRequired
        let labelRightConstraint = NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
        let labelWidthConstraint = NSLayoutConstraint(item: label, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
        self.labelHeightConstraint = NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
//        labelHeightConstraint.priority = UILayoutPriorityDefaultLow
        
		let containerTopConstraint = NSLayoutConstraint(item: containerView, attribute: .top, relatedBy: .equal, toItem: label, attribute: .bottom, multiplier: 1, constant: 0)
//        containerTopConstraint.priority = UILayoutPriorityRequired
		let containerRightConstraint = NSLayoutConstraint(item: containerView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
		let containerWidthConstraint = NSLayoutConstraint(item: containerView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
		self.containerHeightConstraint = NSLayoutConstraint(item: containerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		
		let buttonTopConstraint = NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0)
//        buttonTopConstraint.priority = UILayoutPriorityRequired
		let buttonRightConstraint = NSLayoutConstraint(item: button, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
		let buttonWidthConstraint = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
		let buttonHeightConstraint = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 44)
		
		self.viewHeightConstraint = NSLayoutConstraint(item: self.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 44)
        self.viewWidthConstraint = NSLayoutConstraint(item: self.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 225)


        self.view.addConstraints([buttonTopConstraint, buttonRightConstraint, buttonWidthConstraint, buttonHeightConstraint,
                                  containerTopConstraint, containerRightConstraint, containerWidthConstraint, containerHeightConstraint,
                                  labelTopConstraint, labelRightConstraint, labelWidthConstraint, labelHeightConstraint,
                                  viewHeightConstraint, viewWidthConstraint])
        
        update(state: .noConnection)
        Skoog.sharedInstance.searchForSkoog()
    }
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == CBManagerState.poweredOff {
            label.text = "Bluetooth Off!"
            let alert = UIAlertController.init(title: "Bluetooth", message: "Turn on Bluetooth to connect your Skoog", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            
//            let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { action in
//                guard let url = NSURL(string: UIApplicationOpenSettingsURLString) else {
//                    return
//                }
//                if UIApplication.shared.canOpenURL(url as URL) {
//                    UIApplication.shared.openURL(url as URL)
//                }
//            })
            
            alert.addAction(defaultAction)
//            alert.addAction(settingsAction)
//            self.present(alert, animated: true, completion: nil)
            print("Bluetooth Off!")
        }
    }
    
    public func skoogConnectionStatus(connected: Bool){
        skoogConnected = connected
        if connected {
            self.update(state: .connected)
        }
        else {
            self.update(state: .noConnection)
        }
    }
    
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
    
    
    
    @objc public func buttonCallback() {
        switch state {
        case .noConnection, .uninitialised :
            update(state: .searching)
  		case .connected :
            update(state: .selecting)
        case .searching:
            update(state: .noConnection)
        case .connecting, .disconnecting, .selecting:
            break
        }
    }
    
    @objc public func buttonTimeoutCallback() {
        if skoogConnected {
            print("button timeout - connected")
            update(state: .connected)
            if UIAccessibilityIsVoiceOverRunning() && enableVoiceOver {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("skoog connected successfully", comment: "Calibration AX success label"))
            }
            bluetoothStopSearch()
        }
        else {
            print("button timeout - not connected")
            update(state: .noConnection)
            if UIAccessibilityIsVoiceOverRunning() && enableVoiceOver {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("no skoogs found", comment: "Calibration AX failure label"))
            }
            bluetoothStopSearch()
        }
    }
    
    public func bluetoothStartSearch() {
        if self.bluetoothMIDIViewController != nil {
            self.bluetoothMIDIViewController?.delegate = self
        }
        else {
            self.bluetoothMIDIViewController = BluetoothMIDI.init()
            self.bluetoothMIDIViewController?.delegate = self
            
            self.addChildViewController(bluetoothMIDIViewController!)
            
            self.bluetoothMIDIViewController?.tableView.backgroundColor	=  UIColor(white: 1.0, alpha: 0.2)
            self.containerView.addSubview((bluetoothMIDIViewController?.view)!)

            if let v = self.bluetoothMIDIViewController?.tableView {
                v.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    v.widthAnchor.constraint(equalTo: self.containerView.widthAnchor),
                    v.heightAnchor.constraint(equalTo: self.containerView.heightAnchor),
                    v.topAnchor.constraint(equalTo: self.containerView.topAnchor),
                    v.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
                    v.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
                ])
                v.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }
        }
    }
    
    public func bluetoothStopSearch() {
        if self.bluetoothMIDIViewController != nil {
            self.bluetoothMIDIViewController?.delegate = nil
        }
    }
    
    
    public func updateCell(width: CGFloat){
//        self.viewWidthConstraint.constant = width
//        animateIfNeeded(duration: 0.3)
    }
    
    
	public func update(state: State) {
		if state != self.state {
            self.state = state
            stopTimer()
            
			switch state {
			case .noConnection:
                bluetoothStopSearch()
				self.button.setImage(nil, for: .normal)
                button.setTitle(NSLocalizedString("Connect Skoog", comment: "connect Skoog text"), for: .normal)
                self.button.accessibilityLabel = NSLocalizedString("Connect Skoog", comment: "connect Skoog text")
                self.button.accessibilityHint = NSLocalizedString("Click here to connect your skoog", comment: "connect Skoog AX hint text")
                self.button.tintColor = swiftRed
                updateConstraints(containerH: 0, labelH: 0, height: 44, width: button.intrinsicContentSize.width + 88)
                self.button.isUserInteractionEnabled = true

            case .searching :
				self.button.setImage(loadingImage, for: .normal)
                self.button.imageView?.accessibilityLabel = NSLocalizedString("Searching for Skoog", comment: "searching for Skoog text")
                self.button.accessibilityLabel = NSLocalizedString("Searching for Skoog", comment: "searching for Skoog text")
                self.button.tintColor = .black
                self.button.setTitle(NSLocalizedString("Searching for Skoog", comment: "searching for Skoog text"), for: .normal)
                self.button.isUserInteractionEnabled = false
                updateConstraints(containerH: 0, labelH: 0, height: 44, width: button.intrinsicContentSize.width + 44)
                self.button.imageView?.startRotating()
                self.searchTimer = Timer.scheduledTimer(timeInterval:4.0, target: self, selector: #selector(buttonTimeoutCallback), userInfo: nil, repeats: false)
                self.bluetoothStartSearch()

			case .selecting :
                self.button.setImage(loadingImage, for: .normal)
                self.button.imageView?.accessibilityLabel = NSLocalizedString("Loading", comment: "Loading image AX label")
                self.button.accessibilityLabel = NSLocalizedString("Loading", comment: "Loading image AX label")
				self.button.setTitle("", for: .normal)
                updateConstraints(containerH: 144, labelH: 44, height: 232, width: 250)
                self.searchTimer = Timer.scheduledTimer(timeInterval:6.0, target: self, selector: #selector(buttonTimeoutCallback), userInfo: nil, repeats: false)
                self.bluetoothStartSearch()
                self.button.imageView?.startRotating()
                
            case .connecting :
                self.button.setImage(loadingImage, for: .normal)
                self.button.imageView?.accessibilityLabel = NSLocalizedString("Connecting skoog", comment: "bluetooth midi label text connecting")
                self.button.accessibilityLabel = NSLocalizedString("Connecting skoog", comment: "bluetooth midi label text connecting")
                self.button.imageView?.startRotating()
                self.button.tintColor = .black
                self.button.setTitle(NSLocalizedString("Connecting Skoog", comment: "bluetooth midi label text connecting"), for: .normal)
                updateConstraints(containerH:0, labelH: 0, height: 44, width: button.intrinsicContentSize.width + 44)
                self.button.imageView?.startRotating()

			case .connected :
                self.button.imageView?.stopRotating()
				self.button.setImage(UIImage(named: "skios_skoog_baricon"), for: .normal)
                self.button.imageView?.accessibilityLabel = NSLocalizedString("skoog connected", comment: "connected image AX label")
                self.button.accessibilityLabel = NSLocalizedString("skoog connected", comment: "connected image AX label")
                self.button.accessibilityHint = NSLocalizedString("Click here to disconnect your skoog", comment: "connect Skoog AX hint text")
                if UIAccessibilityIsVoiceOverRunning() && enableVoiceOver {
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("skoog connected successfully", comment: "Calibration AX success label"))
                }
                self.button.setTitle(NSLocalizedString("Skoog", comment: "Skoog text"), for: .normal)
				self.button.tintColor = swiftRed
				self.button.isUserInteractionEnabled = true
                updateConstraints(containerH: 0, labelH: 0, height: 44, width: button.intrinsicContentSize.width + 28)

			case .disconnecting :
                self.searchTimer = Timer.scheduledTimer(timeInterval:0.4, target: self, selector: #selector(buttonTimeoutCallback), userInfo: nil, repeats: false)
            case .uninitialised :
                break
            }
		}
    }
    
    public func updateConstraints(containerH:CGFloat, labelH: CGFloat, height: CGFloat, width:CGFloat){
        self.containerHeightConstraint.constant = containerH
        self.viewHeightConstraint.constant = height
//        animateIfNeeded(duration: 0.1)
        self.viewWidthConstraint.constant = width
        self.labelHeightConstraint.constant = labelH
        self.view.setNeedsLayout()
        
        //animateIfNeeded(duration: 0.01)
        
        
//        UIView.animate(withDuration: 0.05, animations: {
//            self.labelHeightConstraint.constant = labelH
//            self.containerHeightConstraint.constant = containerH
//            self.viewHeightConstraint.constant = height
//            self.view.layoutIfNeeded()
//        }, completion: { completion in
//            UIView.animate(withDuration: 0.05, animations: {
//                self.viewWidthConstraint.constant = width
//                self.view.layoutIfNeeded()
//            }, completion: nil)
//        })
//
        
//        UIView.a
//        {
//            self.viewWidthConstraint.constant = width
//            self.labelHeightConstraint.constant = labelH
//        }
        
    }
    
    func stopTimer() {
        if self.searchTimer != nil {
            if (self.searchTimer?.isValid)! {
                self.searchTimer?.invalidate()
            }
        }
    }
    
    func animateIfNeeded(duration: TimeInterval? = 0.3) {
        UIView.animate(withDuration: duration!) {
//                    self.view.layoutIfNeeded()
                self.view.setNeedsLayout()
            
        }
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        myBTManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        //Skoog.sharedInstance.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}

public class ConnectionButton:  UIButton {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    public override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        return CGRect(x: 8, y: 8, width: 28, height: 28)
    }
    
    public override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        return CGRect(x: 44, y: 0, width: 300, height: 44)
    }
}

