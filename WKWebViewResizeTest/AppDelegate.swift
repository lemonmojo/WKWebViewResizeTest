import Cocoa
import WebKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	private var webWindowController: WebWindowController?
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		openWebWindow()
	}
	
	private func openWebWindow() {
		guard let url = Bundle(for: Self.self).url(forResource: "resizetest",
												   withExtension: "html") else {
			fatalError("Failed to get embedded HTML URL")
		}
		
//		guard let url = URL(string: "https://www.w3schools.com/jsref/met_win_open.asp") else {
//			fatalError("Failed to parse URL")
//		}
		
		openWebWindow(withURL: url)
	}
	
	private func openWebWindow(withURL url: URL) {
		let windowController = WebWindowController(url: url)
		self.webWindowController = windowController
		
		windowController.showWindow(nil)
	}
}
