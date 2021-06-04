/*
 *  PreviewTextView.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 03/06/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */


import Cocoa


class PreviewTextView: NSTextView {

    // A very basic override so we can adjust the cursor
    
    override func mouseMoved(with event: NSEvent) {
        
        // Re-set the cursor to an arrow on mouse movement
        NSCursor.arrow.set()
    }
    
}
