import SwiftUI

#if os(macOS)
import AppKit

/// A native macOS ScrollView that forces the horizontal scrollbar to be permanently visible.
struct NativeHorizontalScrollView<Content: View>: NSViewRepresentable {
    let content: Content
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy // This forces the "always-on" style
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        
        // Ensure the scroller is actually visible immediately
        scrollView.horizontalScroller?.isHidden = false
        
        let hostingView = NSHostingView(rootView: content)
        scrollView.documentView = hostingView
        
        // Use a more robust way to ensure the document view fits the content
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            hostingView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
            // Do NOT constrain the trailing anchor, let it grow based on SwiftUI content
        ])
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let hostingView = nsView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content
        }
    }
}
#endif
