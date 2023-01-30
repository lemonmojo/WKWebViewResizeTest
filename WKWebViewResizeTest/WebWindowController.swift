import Foundation
import AppKit
import WebKit

class WebWindowController: NSWindowController {
	public let webView: WKWebView
	public let isPopUp: Bool
	
	private static var windowDidResizeHandlerCount = 0
	
	private var awoken = false
	
	private var subWindowControllers = [WebWindowController]()
	
	override var windowNibName: NSNib.Name? { "WebWindow" }
	
	init(webView: WKWebView,
		 isPopUp: Bool) {
		self.webView = webView
		self.isPopUp = isPopUp
		
		super.init(window: nil)
		
		webView.uiDelegate = self
		
		injectResizeHandler()
	}
	
	convenience init(url: URL) {
		let webView = WKWebView()
		
		self.init(webView: webView,
				  isPopUp: false)
		
		webView.loadFileURL(url,
							allowingReadAccessTo: url)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func awakeFromNib() {
		guard !awoken else { return }
		awoken = true
		
		guard let contentView = window?.contentView else {
			return
		}
		
		webView.frame = contentView.bounds
		
		webView.autoresizingMask = [ .minXMargin, .maxXMargin,
									 .minYMargin, .maxYMargin,
									 .width, .height ]
		
		contentView.addSubview(webView)
	}
}

private extension WebWindowController {
	func injectResizeHandler() {
		let contentController = webView.configuration.userContentController
		
		let name = "windowDidResizeHandler\(Self.windowDidResizeHandlerCount)"
		
		Self.windowDidResizeHandlerCount += 1
		
		contentController.add(self,
							  name: name)
		
		let js = """
			window.addEventListener("resize", function(event) {
				if (window.webkit &&
					window.webkit.messageHandlers &&
					window.webkit.messageHandlers.\(name)) {
					window.webkit.messageHandlers.\(name).postMessage({
						"size": {
							"width": window.innerWidth,
							"height": window.innerHeight
						}
					});
				}
			});
		"""

		let script = WKUserScript(source: js,
								  injectionTime: .atDocumentEnd,
								  forMainFrameOnly: true)
		
		contentController.addUserScript(script)
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
			frame = .init(x: 0, y: 0, width: width, height: height)
		} else {
			frame = .init(x: 0, y: 0, width: 800, height: 500)
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
}

extension WebWindowController: WKScriptMessageHandler {
	func userContentController(_ userContentController: WKUserContentController,
							   didReceive message: WKScriptMessage) {
		guard let dict = message.body as? [String: AnyObject] else {
			return
		}
		
		guard let sizeDict = dict["size"] as? [String: Double] else {
			return
		}
		
		guard let width = sizeDict["width"],
			  let height = sizeDict["height"] else {
			return
		}
		
		let size = CGSize(width: width,
						  height: height)

		print("Resized to \(size)")
	}
}
