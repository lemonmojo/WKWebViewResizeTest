import Cocoa
import WebKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	private var webWindowController: WebWindowController?
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		openWebWindow()
	}
	
	private func openWebWindow() {
		let bundle = Bundle(for: Self.self)
		
		guard let url = bundle.url(forResource: "resizetest",
								   withExtension: "html") else {
			return
		}
		
		let windowController = WebWindowController(url: url)
		self.webWindowController = windowController
		
		windowController.showWindow(nil)
	}
}
