/*
 *  PreviewTextView.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 03/06/2021.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */


import Cocoa


/**
 A very basic subclass so we can adjust the cursor hovering over theme previews.
*/

class PreviewTextView: NSTextView {

    override func mouseMoved(with event: NSEvent) {
        
        // Re-set the cursor to an arrow on mouse movement
        NSCursor.arrow.set()
    }
    
}
