import Foundation
import AppKit
import WebKit

class WebWindowController: NSWindowController {
	public let webView: WKWebView
	public let isPopUp: Bool
	
	private static let defaultSetWindowFrame = NSRect(x: 0, y: 0,
													  width: 100, height: 100)
	
	private var awoken = false
	private var hasSetWindowFrameBeenCalled = false
	private var subWindowControllers = [WebWindowController]()
	
	override var windowNibName: NSNib.Name? { "WebWindow" }
	
	init(webView: WKWebView,
		 isPopUp: Bool) {
		self.webView = webView
		self.isPopUp = isPopUp
		
		super.init(window: nil)
	}
	
	convenience init(url: URL) {
		let webView = WKWebView()
		
		webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
		
		self.init(webView: webView,
				  isPopUp: false)
		
		if url.isFileURL {
			webView.loadFileURL(url,
								allowingReadAccessTo: url)
		} else {
			webView.load(.init(url: url))
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func awakeFromNib() {
		guard !awoken else { return }
		awoken = true
		
		guard let contentView = window?.contentView else { return }
		
		webView.frame = contentView.bounds
		
		webView.autoresizingMask = [ .minXMargin, .maxXMargin,
									 .minYMargin, .maxYMargin,
									 .width, .height ]
		
		contentView.addSubview(webView)
		
		webView.uiDelegate = self
	}
}

extension WebWindowController: WKUIDelegate {
	func webView(_ webView: WKWebView,
				 createWebViewWith configuration: WKWebViewConfiguration,
				 for navigationAction: WKNavigationAction,
				 windowFeatures: WKWindowFeatures) -> WKWebView? {
		let width = windowFeatures.width?.doubleValue
		let height = windowFeatures.height?.doubleValue
		
		let frame: CGRect
		
		if let width,
			let height {
			frame = .init(x: 0, y: 0,
						  width: width, height: height)
		} else {
			frame = .init(x: 0, y: 0,
						  width: 800, height: 500)
		}
		
		let newWebView = WKWebView(frame: frame,
								   configuration: configuration)
		
		let windowController = WebWindowController(webView: newWebView,
												   isPopUp: true)
		
		subWindowControllers.append(windowController)
		
		windowController.showWindow(nil)
		
		windowController.window?.setContentSize(frame.size)
		
		return newWebView
	}
	
	/// WARNING: Private API!
	@objc(_webView:getWindowFrameWithCompletionHandler:)
	func _webView(_ webView: WKWebView,
				  completionHandler: (_: CGRect) -> ()) {
		let windowFrame = webView.bounds
		
		print("Asked for window frame: \(windowFrame)")
		
		completionHandler(windowFrame)
	}
	
	/// WARNING: Private API!
	@objc(_webView:setWindowFrame:)
	func _webView(_ webView: WKWebView,
				  setWindowFrame windowFrame: NSRect) {
		guard isPopUp else { return }
		
		let originalHasSetWindowFrameBeenCalled = hasSetWindowFrameBeenCalled
		
		self.hasSetWindowFrameBeenCalled = true
		
		if !originalHasSetWindowFrameBeenCalled,
		   windowFrame == Self.defaultSetWindowFrame {
			return
		}
		
		print("Asked to resize window to \(windowFrame)")
		
		webView.window?.setContentSize(windowFrame.size)
	}
}
