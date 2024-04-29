/*
 *  PCImageView.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 18/06/2021.
 *  Copyright © 2024 Tony Smith. All rights reserved.
 */


import Cocoa


/**
 A very basic subclass so we can dfraw a line around theme mode icons in Preferences.
*/

class PCImageView: NSImageView {
    
    // MARK: - Private Properties
    
    private var outline: Bool = false
    
    
    // MARK: - Public Properties
    
    var isOutlined: Bool {
        get {
            return self.outline
        }
        set(newValue) {
            self.outline = newValue
            self.needsDisplay = true
        }
    }
    
    
    // MARK: - Public Functions
    
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
