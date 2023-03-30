//
//  PCImageView.swift
//  PreviewCode
//
//  Created by Tony Smith on 30/03/2023.
//

import Cocoa

class PCImageView: NSImageView {
    
    private var outline: Bool = false
    
    var isOutlined: Bool {
        get {
            return self.outline
        }
        set(newValue) {
            self.outline = newValue
            self.needsDisplay = true
        }
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)

        if let gc: NSGraphicsContext = NSGraphicsContext.current {
            // Lock the context
            gc.saveGraphicsState()

            // Set the colours we'll be using
            if self.outline {
                NSColor.controlAccentColor.setStroke()
                self.alphaValue = 1.0
            } else {
                NSColor.clear.setStroke()
                self.alphaValue = 0.6
            }

            // Make the outline
            let highlightPath: NSBezierPath = NSBezierPath(roundedRect: self.bounds,
                                                           xRadius: 4.0,
                                                           yRadius: 4.0)
            highlightPath.lineWidth = 2.0
            highlightPath.stroke()

            // Unlock the context
            gc.restoreGraphicsState()
        }
    }
    
}
