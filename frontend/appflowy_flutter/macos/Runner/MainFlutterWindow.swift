import Cocoa
import FlutterMacOS

private let kTrafficLightOffetTop = 14

class MainFlutterWindow: NSWindow {
  func registerMethodChannel(flutterViewController: FlutterViewController) {
    let cocoaWindowChannel = FlutterMethodChannel(name: "flutter/cocoaWindow", binaryMessenger: flutterViewController.engine.binaryMessenger)
    cocoaWindowChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: FlutterResult) -> Void in
      if call.method == "setWindowPosition" {
        guard let position = call.arguments as? NSArray else {
          result(nil)
          return
        }
        let nX = position[0] as! NSNumber
        let nY = position[1] as! NSNumber
        let x = nX.doubleValue
        let y = nY.doubleValue

        self.setFrameOrigin(NSPoint(x: x, y: y))
        result(nil)
        return
      } else if call.method == "getWindowPosition" {
        let frame = self.frame
        result([frame.origin.x, frame.origin.y])
        return
      } else if call.method == "zoom" {
        self.zoom(self)
        result(nil)
        return
      }

      result(FlutterMethodNotImplemented)
    })
  }

  func layoutTrafficLightButton(titlebarView: NSView, button: NSButton, offsetTop: CGFloat, offsetLeft: CGFloat) {
    button.translatesAutoresizingMaskIntoConstraints = false;
    titlebarView.addConstraint(NSLayoutConstraint.init(
      item: button,
      attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: titlebarView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: offsetTop))
    titlebarView.addConstraint(NSLayoutConstraint.init(
      item: button,
      attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: titlebarView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: offsetLeft))
  }

  func layoutTrafficLights() {
    let closeButton = self.standardWindowButton(ButtonType.closeButton)!
    let minButton = self.standardWindowButton(ButtonType.miniaturizeButton)!
    let zoomButton = self.standardWindowButton(ButtonType.zoomButton)!
    let titlebarView = closeButton.superview!

    self.layoutTrafficLightButton(titlebarView: titlebarView, button: closeButton, offsetTop: CGFloat(kTrafficLightOffetTop), offsetLeft: 12)
    self.layoutTrafficLightButton(titlebarView: titlebarView, button: minButton, offsetTop: CGFloat(kTrafficLightOffetTop), offsetLeft: 30)
    self.layoutTrafficLightButton(titlebarView: titlebarView, button: zoomButton, offsetTop: CGFloat(kTrafficLightOffetTop), offsetLeft: 48)

    let customToolbar = NSTitlebarAccessoryViewController()
    let newView = NSView()
    newView.frame = NSRect(origin: CGPoint(), size: CGSize(width: 0, height: 40))  // only the height is cared
    customToolbar.view = newView
    self.addTitlebarAccessoryViewController(customToolbar)
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController

    self.registerMethodChannel(flutterViewController: flutterViewController)

    self.setFrame(windowFrame, display: true)
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(StyleMask.fullSizeContentView)
    self.isMovableByWindowBackground = true

    // For the macOS version 15 or higher, set it to true to enable the window tiling
    if #available(macOS 15.0, *) {
      self.isMovable = true
    } else {
      self.isMovable = false
    }

    self.layoutTrafficLights()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
